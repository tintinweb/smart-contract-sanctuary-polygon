/**
 *Submitted for verification at polygonscan.com on 2022-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

contract Bet {
    address payable private contractOwner = payable(0x00000000001aCCFa9CEf68CF5371A23025B6D4b6);
    uint256 public duelSizeSmall = 1000000000000000000 wei;
    uint256 public fee = duelSizeSmall / 333;

    enum OfferState {
        READY,
        WIN1,
        WIN2,
        CLOSED
    }

    struct Offer {
        uint256 offerId;
        OfferState state;
        address owner;
        uint256 ask;
    }

    mapping (uint256 => Offer) public offers;
    uint256 public offersSize;

    function makeOffer(uint256 ask) public payable returns (Offer memory) {
        require(msg.value == ask, "deposited incorrect ammount");
        offers[offersSize] = Offer(offersSize, OfferState.READY, msg.sender, msg.value);
        offersSize++;
        return offers[offersSize];
    }

    function acceptOffer(uint256 offerId) public payable returns (Offer memory) {
        require(offerId <= offersSize, "offer non existant");
        require(offers[offerId].state == OfferState.READY, "offer is not ready");
        require(offers[offerId].ask == msg.value, "deposited value != offer ask");

        address payable winner;
        bool isWin = isAccepterWinner();
        if (isWin) {
            winner = payable(msg.sender);
            offers[offerId].state = OfferState.WIN1;
        } else {
            winner = payable(offers[offerId].owner);
            offers[offerId].state = OfferState.WIN2;
        }

        winner.transfer(offers[offerId].ask * 2 - fee);
        return offers[offerId];
    }

    function cancelOffer(uint256 offerId) public payable {
        require(offerId <= offersSize, "offer non existant");
        Offer memory offer = offers[offerId];
        require(offer.state == OfferState.READY, "offer is not ready");
        require(offer.owner == msg.sender, "you are not the offer owner");

        payable(offer.owner).transfer(offer.ask);
    }

    function getReadyOffers() public view returns (Offer[] memory) {
        Offer[] memory ret = new Offer[](offersSize);
        uint i;
        uint len = 0;
        for (i = 0; i < offersSize; i++) {
            Offer memory curOffer = offers[i];
            if (curOffer.state == OfferState.READY) {
                ret[len++] = offers[i];
            }
        }
        return ret;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public {
        require(msg.sender == contractOwner, "you are not the contract owner");
        payable(msg.sender).transfer(address(this).balance);
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        offersSize
                    )
                )
            );
    }

    function isAccepterWinner() private view returns (bool) {
        uint256 rand = random();
        return rand % 10000 < 5000;
    }
}