// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOwnable} from "../../common/interfaces/IOwnable.sol";
import {IAutoCompounderFactory} from "./interfaces/IAutoCompounderFactory.sol";
import {AutoCompounder} from "../AutoCompounder.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {ITokenVotes} from "../../erc3643/token/ITokenVotes.sol";
import {IIdentityRegistry} from "../../erc3643/registry/interface/IIdentityRegistry.sol";
import {IIdentity} from "../../onchainid/interface/IIdentity.sol";
import {IdentityGateway} from "../../onchainid/gateway/Gateway.sol";

/**
 * @title AutoCompounder Factory
 * @author Hashgraph
 *
 * The contract which allows to deploy AutoCompounder with different parameters
 * and track contract addresses.
 */
contract AutoCompounderFactory is IAutoCompounderFactory, Ownable, ERC165 {
    // Used salt => deployed AutoCompounder
    mapping(string => address) public autoCompounderDeployed;

    IdentityGateway private idGateway;

    /**
     * @dev Initializes contract with passed parameters.
     */
    constructor(address _idGateway) Ownable(msg.sender) {
        idGateway = IdentityGateway(_idGateway);
    }

    /**
     * @dev Deploys an AutoCompounder using CREATE2 opcode.
     * @notice It's required to send at least 18 HBAR for token creation and associations.
     *
     * @param salt The CREATE2 salt.
     * @param autoCompounderDetails The AutoCompounder parameters.
     * @return autoCompounder The address of the deployed AutoCompounder.
     */
    function deployAutoCompounder(
        string calldata salt,
        AutoCompounderDetails calldata autoCompounderDetails
    ) external payable returns (address autoCompounder) {
        require(autoCompounderDeployed[salt] == address(0), "AutoCompounderFactory: AutoCompounder already deployed");
        require(
            autoCompounderDetails.uniswapV2Router != address(0),
            "AutoCompounderFactory: Invalid Uniswap Router address"
        );
        require(autoCompounderDetails.vault != address(0), "AutoCompounderFactory: Invalid Vault address");
        require(autoCompounderDetails.usdc != address(0), "AutoCompounderFactory: Invalid USDC address");

        autoCompounder = _deployAutoCompounder(salt, autoCompounderDetails);

        autoCompounderDeployed[salt] = autoCompounder;

        IERC4626 vault = IERC4626(autoCompounderDetails.vault);
        ITokenVotes erc3643Token = ITokenVotes(vault.asset());
        
        // check if asset is an erc3643 token and register identity for the ac
        try erc3643Token.identityRegistry() returns (IIdentityRegistry registry) {
            IIdentity identity = IIdentity(idGateway.deployIdentityForWallet(autoCompounder));
            registry.registerIdentity(autoCompounder, identity, 840);
        } catch  {
            // do nothing
        }

        IOwnable(autoCompounder).transferOwnership(msg.sender);

        emit AutoCompounderDeployed(
            autoCompounder,
            autoCompounderDetails.vault,
            autoCompounderDetails.aTokenName,
            autoCompounderDetails.aTokenSymbol
        );
    }

    /**
     * @dev Creates deployment data for the CREATE2 opcode.
     *
     * @return The the address of the contract created.
     */
    function _deployAutoCompounder(
        string calldata salt,
        AutoCompounderDetails calldata autoCompounderDetails
    ) private returns (address) {
        bytes memory _code = type(AutoCompounder).creationCode;
        bytes memory _constructData = abi.encode(
            autoCompounderDetails.uniswapV2Router,
            autoCompounderDetails.vault,
            autoCompounderDetails.usdc,
            autoCompounderDetails.aTokenName,
            autoCompounderDetails.aTokenSymbol,
            autoCompounderDetails.operator
        );

        bytes memory deploymentData = abi.encodePacked(_code, _constructData);
        return _deploy(salt, deploymentData);
    }

    /**
     * @dev Deploy function with create2 opcode call.
     *
     * @return The the address of the contract created.
     */
    function _deploy(string calldata salt, bytes memory bytecode) private returns (address) {
        bytes32 saltBytes = bytes32(keccak256(abi.encodePacked(salt)));
        address addr;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encoded_data := add(0x20, bytecode) // load initialization code.
            let encoded_size := mload(bytecode) // load init code's length.
            addr := create2(callvalue(), encoded_data, encoded_size, saltBytes)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return addr;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IAutoCompounderFactory).interfaceId || super.supportsInterface(interfaceId);
    }
}
