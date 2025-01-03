// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Building} from "./Building.sol";
import {IERC721Metadata} from "../erc721/interface/IERC721Metadata.sol";
import {Token} from '../erc3643/token/Token.sol';

/**
 * @title BuildingFactory
 * @author Hashgraph 
 */
contract BuildingFactory is OwnableUpgradeable  {
    address private nft;
    address private uniswapRouter;
    address private uniswapFactory;
    address private buildingBeacon;

    BuildingInfo[] public buildingsList;

    event NewBuilding(address addr);

    struct BuildingInfo {
        address addr; // building address
        uint256 nftId; // NFT token ID attributed to the building
        string tokenURI; // NFT metadatada location
    }

    /**
     * initialize used for upgradable contract
     * @param _nft NFT collection address
     * @param _uniswapRouter unsiswap router address
     * @param _uniswapFactory unsiswap factory address
     */
    function initialize(
        address _nft,
        address _uniswapRouter,
        address _uniswapFactory,
        address _buildingBeacon
    ) public virtual initializer {
        __Ownable_init(_msgSender());
        nft = _nft;
        uniswapRouter = _uniswapRouter;
        uniswapFactory = _uniswapFactory;
        buildingBeacon = _buildingBeacon;
    }

    /**
     * newBuilding Creates new building with create2, mints NFT and store it.
     * @param tokenURI metadata location
     */
    function newBuilding(string memory tokenURI) public virtual onlyOwner {
        BeaconProxy buildingProxy = new BeaconProxy(
            buildingBeacon,
            abi.encodeWithSelector(Building.initialize.selector, uniswapRouter, uniswapFactory, nft)
        );

        uint256 tokenId = IERC721Metadata(nft).mint(address(buildingProxy), tokenURI);

        buildingsList.push(BuildingInfo(
            address(buildingProxy),
            tokenId,
            tokenURI
        ));

        emit NewBuilding(address(buildingProxy));
    }
}
