// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable {
    struct Order {
        address seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        bool active;
        bytes signature;
        uint256 deadline;
    }

    mapping(uint256 => Order) public orders;
    uint256 public orderCounter;

    event OrderCreation(
        uint256 orderCounter,
        address seller,
        address tokenAddress,
        uint256 tokenId,
        uint256 price,
        bytes signature,
        uint256 deadline
    );

    event OrderExecuted(
        uint256 orderId,
        address to,
        address seller,
        address tokenAddress,
        uint256 tokenId,
        uint256 price
    );

    function createOrder(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        bytes memory _signature,
        uint256 _deadline
    ) public {
        // Check if the owner is the actual owner of the token
        require(
            msg.sender == IERC721(_tokenAddress).ownerOf(_tokenId),
            "Only token owner can create a listing"
        );
        // Check if the owner has approved this contract to spend their tokens
        require(
            IERC721(_tokenAddress).isApprovedForAll(msg.sender, address(this)),
            "Token owner must approve this contract"
        );
        // Check if the token address is valid
        require(_tokenAddress != address(0), "Invalid token address");
        // Check if the token address has code
        uint256 size;
        assembly {
            size := extcodesize(_tokenAddress)
        }
        require(size > 0, "not a token address");
        // Check if the price is greater than 0
        require(_price > 0, "Price must be greater than 0");
        // Check if the deadline is in the future
        require(_deadline > block.timestamp, "Invalid deadline");

        Order storage newOrder = orders[orderCounter];
        newOrder.seller = msg.sender;
        newOrder.tokenAddress = _tokenAddress;
        newOrder.tokenId = _tokenId;
        newOrder.price = _price;
        newOrder.active = true;
        newOrder.signature = _signature;
        newOrder.deadline = _deadline;

        emit OrderCreation(
            orderCounter,
            msg.sender,
            _tokenAddress,
            _tokenId,
            _price,
            _signature,
            _deadline
        );

        orderCounter++;
    }

    function executeOrder(uint256 _orderId) public payable {
        require(_orderId < orderCounter, "Invalid listing ID");
        Order storage order = orders[_orderId];

        // Check if the order is active
        require(order.active, "Order is not active");

        // Check if the transaction value matches the order price
        require(
            msg.value == order.price,
            "Transaction value does not match order price"
        );

        // Check if the deadline has not passed
        require(block.timestamp <= order.deadline, "Order has expired");

        // Perform signature verification
        require(
            _verifySignature(
                order.tokenAddress,
                order.tokenId,
                order.price,
                order.seller,
                order.signature
            ),
            "Invalid signature"
        );

        // Transfer the token to the buyer
        IERC721(order.tokenAddress).transferFrom(
            order.seller,
            msg.sender,
            order.tokenId
        );

        // Transfer the funds to the seller
        payable(order.seller).transfer(msg.value);

        // Deactivate the order
        order.active = false;

        emit OrderExecuted(
            _orderId,
            msg.sender,
            order.seller,
            order.tokenAddress,
            order.tokenId,
            order.price
        );
    }

    function _verifySignature(
        address tokenAddress,
        uint256 tokenId,
        uint256 price,
        address seller,
        bytes memory signature
    ) internal pure returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(tokenAddress, tokenId, price, seller)
        );
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        return recoverSigner(ethSignedMessageHash, signature) == seller;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}
