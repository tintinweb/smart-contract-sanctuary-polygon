// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.9;

contract FontPayments {
    uint256 public minPayment = 0.1 ether;
    uint256 public fontCount = 0;

    struct Buyer {
        uint256 amountPaid;
        uint256 lastPurchase;
        string ipfsHash;
    }
    mapping(address => Buyer) public buyers;

    struct Font {
        uint256 id;
        string name;
        uint256 price;
        address payable creator;
    }

    mapping(string => Font) public fonts;

    event FontCreated(
        uint256 id,
        string ipfsHash,
        string name,
        uint256 price,
        address payable creator
    );

    function addFont(
        string memory _ipfsHash,
        string memory _name,
        uint256 _price,
        address payable _creator
    ) public {
        require(bytes(_ipfsHash).length > 0);
        require(bytes(_name).length > 0);
        require(msg.sender != address(0x0));
        fontCount++;
        fonts[_ipfsHash] = Font(fontCount, _name, _price, _creator);
        emit FontCreated(fontCount, _ipfsHash, _name, 0, _creator);
    }

    event Paid(uint256 amount, uint256 when);

    function payment(string memory _ipfsHash) external payable {
        require(
            msg.value > minPayment,
            "Payment needs to be more than 0.1 Matic"
        );

        Font memory selectedFont = fonts[_ipfsHash];

        (bool success, ) = payable(selectedFont.creator).call{value: msg.value}(
            ""
        );
        require(success, "send ether failure");
        buyers[msg.sender] = Buyer(msg.value, block.timestamp, _ipfsHash);
        emit Paid(msg.value, block.timestamp);
    }
}