// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "../extensions/BuildingERC20.sol";
// import {ITREXGateway} from "../../erc3643/factory/ITREXGateway.sol";
// import {ITREXFactory} from "../../erc3643/factory/ITREXFactory.sol";
// import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library BuildingToken {
    using Bits for uint256; // used to create HTS token

    function createERC3643Token(address /*trexGateway*/, address /*buildingAddress*/, string memory name, string memory symbol, uint8 decimals) internal returns (address) {
        // use simple ERC20 tokens for now, this will be replaced later to ERC3643 token
        // ITREXGateway(trexGateway).deployTREXSuite(
        //     buildTokenDetails(buildingAddress, name, symbol, decimals), 
        //     buildTokenClaimDetails()
        // );

        // string memory salt  = string(abi.encodePacked(Strings.toHexString(buildingAddress), name));
        // address factory = ITREXGateway(trexGateway).getFactory();
        // address token = ITREXFactory(factory).getToken(salt);

        return address(new BuildingERC20(name, symbol, decimals));
    }

    // function buildTokenDetails(address buildingAddress, string memory name, string memory symbol, uint8 decimals) internal pure returns (ITREXFactory.TokenDetails memory)  {
    //     address irs = address(0);
    //     address onchainid = address(0);
    //     address[] memory irsAgents = new address[](0);
    //     address[] memory tokenAgents = new address[](0);
    //     address[] memory complianceModules = new address[](0);
    //     bytes[] memory complianceSettings = new bytes[](0);
        
    //     return ITREXFactory.TokenDetails(
    //         buildingAddress,
    //         name,
    //         symbol,
    //         decimals,
    //         irs,
    //         onchainid, 
    //         irsAgents, 
    //         tokenAgents, 
    //         complianceModules, 
    //         complianceSettings 
    //     );
    // }

    // function buildTokenClaimDetails () internal pure returns (ITREXFactory.ClaimDetails memory) {
    //     uint256[] memory claimTopics = new uint256[](0);
    //     address[] memory issuers = new address[](0);
    //     uint256[][] memory  issuerClaims = new uint256[][](0);
        
    //     return ITREXFactory.ClaimDetails (
    //         claimTopics,
    //         issuers,
    //         issuerClaims
    //     );
    // }
}

library Bits {
    uint256 internal constant ONE = uint256(1);

    /**
     * @dev Sets the bit at the given 'index' in 'self' to '1'.
     *
     * @return Returns the modified value.
     */
    function setBit(uint256 self, uint8 index) internal pure returns (uint256) {
        return self | (ONE << index);
    }
}
