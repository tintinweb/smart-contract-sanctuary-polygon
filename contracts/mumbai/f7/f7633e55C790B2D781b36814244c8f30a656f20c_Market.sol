//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Market {
    uint256 public counter = 0;

    event createProductEvent(string name, address sender);
    event buyProductEvent(string name, uint amount);

    struct Product {
        string name;
        string desc;
        uint256 amount;
        address creator;
        string category;
        string[] img;
        uint256 productId;
        uint status;
    }

    struct Transaction {
        string productName;
        uint productAmount;
        address productCreator;
        uint256 productId;
        string[] img;
        string category;
        bool status;
        address owner;
    }

    struct Delivery {
        string userAddres;
        address buyer;
        address seller;
    }

    mapping(uint256 => Product) public ProductData;
    mapping(uint256 => Transaction) public TransactData;
    mapping(uint256 => mapping(address => bool)) public Escrow;
    mapping(address => uint) public Balances;

    function createProduct(
        string calldata name,
        string calldata desc,
        uint256 amount,
        string calldata category,
        string[] calldata img
    ) external {
        ProductData[counter] = Product(
            name,
            desc,
            amount,
            msg.sender,
            _toLower(category),
            img,
            counter,
            0
        );

        counter++;
        emit createProductEvent(name, msg.sender);
    }

    function buyProduct(uint id) public payable {
        uint amount = ProductData[id].amount;
        require(msg.value >= amount, "You do not have enough matic");
        Escrow[id][msg.sender] = false;
        ProductData[id].status = 1;
        TransactData[id] = Transaction(
            ProductData[id].name,
            ProductData[id].amount,
            ProductData[id].creator,
            id,
            ProductData[id].img,
            ProductData[id].category,
            false,
            msg.sender
        );
        (bool success, ) = address(this).call{value: msg.value}("");
        require(success, "Failed to send Ether");
        emit buyProductEvent(ProductData[id].name, ProductData[id].amount);
    }

    function confirmProduct(uint id, bool status) public {
        if (status == true) {
            Escrow[id][msg.sender] = true;
            ProductData[id].status = 2;
            TransactData[id].status = true;

            Balances[ProductData[id].creator] =
                Balances[ProductData[id].creator] +
                ProductData[id].amount;
        } else {
            Escrow[id][msg.sender] = false;
            ProductData[id].status = 0;
            TransactData[id].status = true;
        }
    }

    function fetchAllProducts() public view returns (Product[] memory) {
        uint256 currentIndex = 0;
        uint256 itemCount = 0;

        for (uint256 i = 0; i < counter; i++) {
            if (ProductData[i].status == 0) {
                itemCount += 1;
            }
        }

        Product[] memory items = new Product[](itemCount);

        for (uint256 i = 0; i < counter; i++) {
            if (ProductData[i].status == 0) {
                uint256 currentId = i;

                Product storage currentItem = ProductData[currentId];
                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyAvailableProducts() public view returns (Product[] memory) {
        uint256 currentIndex = 0;
        uint256 itemCount = 0;

        for (uint256 i = 0; i < counter; i++) {
            if (
                ProductData[i].creator == msg.sender &&
                (ProductData[i].status == 0)
            ) {
                itemCount += 1;
            }
        }

        Product[] memory items = new Product[](itemCount);

        for (uint256 i = 0; i < counter; i++) {
            if (
                ProductData[i].creator == msg.sender &&
                (ProductData[i].status == 0)
            ) {
                uint256 currentId = i;

                Product storage currentItem = ProductData[currentId];
                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyTransactions() public view returns (Transaction[] memory) {
        uint256 currentIndex = 0;
        uint256 itemCount = 0;

        for (uint256 i = 0; i < counter; i++) {
            if (TransactData[i].owner == msg.sender) {
                itemCount += 1;
            }
        }

        Transaction[] memory items = new Transaction[](itemCount);

        for (uint256 i = 0; i < counter; i++) {
            if (TransactData[i].owner == msg.sender) {
                uint256 currentId = i;

                Transaction storage currentItem = TransactData[currentId];
                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyPendingTransactions()
        public
        view
        returns (Transaction[] memory)
    {
        uint256 currentIndex = 0;
        uint256 itemCount = 0;

        for (uint256 i = 0; i < counter; i++) {
            if (
                TransactData[i].owner == msg.sender &&
                TransactData[i].status == false
            ) {
                itemCount += 1;
            }
        }

        Transaction[] memory items = new Transaction[](itemCount);

        for (uint256 i = 0; i < counter; i++) {
            if (
                TransactData[i].owner == msg.sender &&
                TransactData[i].status == false
            ) {
                uint256 currentId = i;

                Transaction storage currentItem = TransactData[currentId];
                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }
        return items;
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function withdraw(uint amount) public {
        uint balance = Balances[msg.sender];
        require(balance >= amount, "You do not have sufficient balance");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}