// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "lib/forge-std/src/Test.sol";
import {NFTMarketplace} from "../src/NftMarketplace.sol";
import {Nft} from "../src/Nft.sol";
import "./HelperFunc.sol";

contract CounterTest is Test {
    NFTMarketplace public nftMarketPlace;
    address owner;
    address addr1;
    address addr2;

    uint256 privKeyA;
    uint256 privKeyB;

    NFTMarketplace.order o;

    function setUp() public {
        nftMarketPlace = new NFTMarketplace();
        nft = new NFT();

        (userA, privKeyA) = mkaddr("USERA");
        (userB, privKeyB) = mkaddr("USERB");

        o = NFTMarketplace.Order({
            seller: address(0),
            tokenAddress: address(nft),
            tokenId: 1,
            price: 2 ether,
            active: false,
            signature: bytes(""),
            deadline: 0
        });

        nft.mint(addr1, 1);
    }

    function testOwnerCannotCreateOrder() public {
        o.seller = addr2;
        switchSigner(addr2);

        vm.expectRevert("Only token owner can create a listing");
        nftMarketPlace.createOrder(o);
    }
}
