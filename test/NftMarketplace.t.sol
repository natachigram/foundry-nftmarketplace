// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "lib/forge-std/src/Test.sol";
import {NFTMarketplace} from "../src/NftMarketplace.sol";
import {Nft} from "../src/Nft.sol";
import "./HelperFunc.sol";

contract NftMarketPlaceTest is Helpers {
    NFTMarketplace public nftMarketPlace;
    Nft public nft;
    address owner;
    address addr1;
    address addr2;

    uint256 privKeyA;
    uint256 privKeyB;

    NFTMarketplace.Order o;

    function setUp() public {
        nftMarketPlace = new NFTMarketplace();
        nft = new Nft("nta", "ntk");

        (addr1, privKeyA) = mkaddr("ADDR1");
        (addr2, privKeyB) = mkaddr("ADDR2");

        o = NFTMarketplace.Order({
            seller: address(0),
            tokenAddress: address(nft),
            tokenId: 1,
            price: 2 ether,
            active: false,
            signature: bytes(""),
            deadline: 0
        });

        nft.mintTo(addr1);
    }

    function testOwnerCannotCreateOrder() public {
        o.seller = addr2;
        switchSigner(addr2);

        vm.expectRevert("Only token owner can create a listing");
        nftMarketPlace.createOrder(
            o.tokenAddress,
            o.tokenId,
            o.price,
            o.signature,
            o.deadline
        );
    }

    function testApproveContract() public {
        switchSigner(addr1);
        vm.expectRevert("Token owner must approve this contract");
        nftMarketPlace.createOrder(
            o.tokenAddress,
            o.tokenId,
            o.price,
            o.signature,
            o.deadline
        );
    }

    function testPrice() public {
        switchSigner(addr1);
        nft.setApprovalForAll(address(nftMarketPlace), true);
        vm.expectRevert("Price must be greater than 0");

        nftMarketPlace.createOrder(
            o.tokenAddress,
            o.tokenId,
            0,
            o.signature,
            o.deadline
        );
    }

    function testDeadline() public {
        switchSigner(addr1);
        nft.setApprovalForAll(address(nftMarketPlace), true);
        vm.expectRevert("Invalid deadline");

        nftMarketPlace.createOrder(
            o.tokenAddress,
            o.tokenId,
            o.price,
            o.signature,
            0
        );
    }

    function testCorrectSignature() public {
        switchSigner(addr1);
        nft.setApprovalForAll(address(nftMarketPlace), true);
        o.deadline = uint88(block.timestamp + 150 minutes);
        o.signature = constructSig(
            o.tokenAddress,
            o.tokenId,
            o.price,
            o.deadline,
            msg.sender,
            privKeyA
        );

        vm.expectRevert("Invalid signature");
        nftMarketPlace.createOrder(
            o.tokenAddress,
            o.tokenId,
            o.price,
            o.signature,
            o.deadline
        );
    }

    function testListingId() public {
        switchSigner(addr1);
        vm.expectRevert("Invalid listing ID");
        nftMarketPlace.executeOrder(1);
    }

    function testActiveOrder() public {
        testCorrectSignature();
        vm.expectRevert("Order is not active");
        nftMarketPlace.executeOrder(0);
    }

    function testingCorrectOrderPrice() public {
        testCorrectSignature();
        vm.expectRevert("Transaction value does not match order price");

        nftMarketPlace.executeOrder{value: o.price}(0);
    }

    function testingzExpiredOrder() public {
        switchSigner(addr1);
        nft.setApprovalForAll(address(nftMarketPlace), true);
        o.deadline = uint88(block.timestamp + 150 minutes);
        o.signature = constructSig(
            o.tokenAddress,
            o.tokenId,
            o.price,
            o.deadline,
            msg.sender,
            privKeyA
        );
        nftMarketPlace.createOrder(
            o.tokenAddress,
            o.tokenId,
            o.price,
            o.signature,
            o.deadline
        );

        vm.expectRevert("Order has expired");

        nftMarketPlace.executeOrder{value: o.price}(0);
    }
}
