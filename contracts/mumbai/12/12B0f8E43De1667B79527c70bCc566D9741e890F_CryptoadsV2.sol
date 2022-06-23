// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "./IERC20.sol";


contract CryptoadsV2 {
    uint public tax;
    address public tax_recipient;
    address public owner;
    bool private initialized;

    Proposal[] public proposals;
    Order[] public orders;

      // Stores a new value in the contract
    function store(uint _tax, address _tax_recipient) public {
        require(!initialized, "Contract instance has already been initialized");
        
        tax = _tax;
        tax_recipient = _tax_recipient;
        owner = msg.sender;
    }

    struct Proposal {
        address influencer;
        uint status;
        uint price;
    }
    struct Order {
        address buyer;
        uint proposal;
        uint status;
        uint price;
    }

    event CloseProposal(uint index, uint status);
    event ApproveOrder(uint index, uint status, string review, uint price, address influencer);
    event CloseOrder(uint index, uint status, string review);
    event CreateOrder(uint index, address buyer, uint status, uint proposal, uint price);
    event CreateProposal(
        uint index,
        address influencer,
        uint status,
        uint price,
        uint audience,
        string description,
        string document,
        uint category,
        uint network,
        uint orders
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not an owner");
        _;
    }

    function __close_proposal(uint index) public {
        // 1 open
        // 0 closed

        if (msg.sender != proposals[index].influencer) {
            revert("You are not an owner");
        }
        if (proposals[index].status == 1) {
            revert("Proposal is closed");
        }

        proposals[index].status = 0; //closed

        emit CloseProposal(index, 0);
    }

    function __create_order(uint index) public payable {
        // 1 paid;
        // 0 not paid
        if (proposals[index].price != msg.value) {
            revert("invalid payment");
        }

        if (proposals[index].status == 0) {
            revert("the proposal is closed");
        }

        Order memory new_order = Order(msg.sender, index, 1, proposals[index].price);

        orders.push(new_order);

        emit CreateOrder(
            orders.length, // index
            msg.sender, // buyer
            1, // status
            index, //proposal
            proposals[index].price //prop price
        );
    }

    function __close_order(uint index, string memory review) public {
        if (orders[index].buyer != msg.sender) {
            revert("you are not an buyer");
        }

        if (orders[index].status == 0) {
            revert("the order closed");
        }

        if (orders[index].status == 2) {
            revert("the order already paid");
        }

        orders[index].status = 0;

        payable(orders[index].buyer).transfer(orders[index].price);

        emit CloseOrder(
          index, // index
          0, //status
          review //
        );
    }

    function __approve_order(uint index, string memory review) public {
        if (orders[index].buyer != msg.sender) {
            revert("you are not an buyer");
        }

        if (orders[index].status == 0) {
            revert("you are not an buyer");
        }

        if (orders[index].status == 2) {
            revert("the order already paid");
        }

        uint _tax = (orders[index].price * tax) / 100;
        uint _payment = orders[index].price - _tax;

        payable(proposals[orders[index].proposal].influencer).transfer(
            _payment
        );
        payable(tax_recipient).transfer(_tax);

        orders[index].status = 2;

        emit ApproveOrder(
          index, // index
          2, //status
          review, //rev
          orders[index].price, //price
          proposals[orders[index].proposal].influencer //influencer
        );
    }

    function __create_proposal(
        uint price,
        uint audience,
        string memory description,
        string memory document,
        uint network,
        uint category
    ) public {
        Proposal memory new_proposal = Proposal(msg.sender, 1, price);

        proposals.push(new_proposal);

        emit CreateProposal(
            proposals.length, // index
            msg.sender, // influencer
            1, // status
            price, // price
            audience, // audience
            description, // description
            document, //document
            category, //
            network, //network
            0 //orders
        );
    }

    function rescueToken(address tokenAddress, uint tokens)
        public
        onlyOwner
    {
        IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function __set_tax(uint _tax) public onlyOwner {

        if(_tax > 15) {
          revert("The Tax is too high");
        }

        tax = _tax;
    }

    function __set_tax_recipient(address _tax_recipient) public onlyOwner {
        tax_recipient = _tax_recipient;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}