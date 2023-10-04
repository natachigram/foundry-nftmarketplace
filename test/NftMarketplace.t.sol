// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "lib/forge-std/src/Test.sol";
import {NFTMarketplace} from "../src/NftMarketplace.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract CounterTest is Test {
    NFTMarketplace public nftMarketPlace;

    function setUp() public {
        nftMarketPlace = new NFTMarketplace();

        address seller;
        address tokenAddress = 0x25D0e89E6Df7ae8C0E8D1D9Bd0991CbE17d10628;
        uint256 tokenId = 1;
        uint256 price = 5;
        uint256 deadline = 466252191;

        seller = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        bytes32 digest = keccak256(
            abi.encodePacked(seller, tokenAddress, tokenId, price, deadline)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80,
            digest
        );
        bytes memory signature = abi.encodePacked(r, s, v);
        nftMarketPlace.createOrder(
            tokenAddress,
            tokenId,
            price,
            signature,
            deadline
        );
    }

    function testCreatOrder() public {
        address tokenAddress = 0x25D0e89E6Df7ae8C0E8D1D9Bd0991CbE17d10628;
        uint256 tokenId = 1;
        uint256 price = 5;
        uint256 deadline = 5 minutes;
        address seller = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        bytes32 digest = keccak256(
            abi.encodePacked(seller, tokenAddress, tokenId, price, deadline)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80,
            digest
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(bytes("Only token owner can create a listing"));

        NFTMarketplace.createOrder(
            tokenAddress,
            tokenId,
            price,
            signature,
            deadline
        );
    }
}
