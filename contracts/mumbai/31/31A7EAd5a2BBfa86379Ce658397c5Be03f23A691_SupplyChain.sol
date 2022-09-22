// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Counters.sol";

// import "hardhat/console.sol";

contract SupplyChain {
    enum UserTypes {
        MANUFACTURER,
        SUPPLIER
    }

    enum TransitTypes {
        ARRIVAL,
        DEPARTURE
    }

    struct User {
        string name;
        UserTypes uType;
        uint[] products;
    }

    struct Product {
        uint uId;
        string name;
        string pType;
        address manufacturer;
        address[] holders;
        uint manTime;
        uint32 quantity;
        uint32 price;
        string currency;
    }

    struct Transit {
        address holder;
        TransitTypes transitType;
        uint time;
    }

    struct ViewRecentTransit {
        uint uId;
        Product product;
        Transit transit;
    }

    struct ViewProduct {
        uint uId;
        Product product;
        Transit[] allTransits;
    }

    mapping(address => User) public users;
    mapping(uint => Product) public products;
    mapping(uint => Transit[]) public transits;
    uint[] public productUIds;
    uint[] private recentTransits;

    using Counters for Counters.Counter;
    Counters.Counter private productCount;

    function random(uint time, string calldata name)
        private
        view
        returns (uint)
    {
        return
            uint(keccak256(abi.encodePacked(block.difficulty, time, name))) %
            1000000000000000;
    }

    function addUser(string calldata name, string calldata uType) public {
        require(
            keccak256(bytes(users[msg.sender].name)) == keccak256(bytes("")),
            "User already exists"
        );

        User memory _newUser;
        _newUser.name = name;

        if (keccak256(bytes(uType)) == keccak256(bytes("manufacturer")))
            _newUser.uType = UserTypes.MANUFACTURER;
        else if (keccak256(bytes(uType)) == keccak256(bytes("supplier")))
            _newUser.uType = UserTypes.SUPPLIER;
        else revert("Invalid user type");

        users[msg.sender] = _newUser;
    }

    function addProduct(
        string calldata name,
        string calldata pType,
        uint manTime,
        uint32 quantity,
        uint32 price,
        string calldata currency
    ) public {
        require(price != 0 && quantity != 0, "Invalid inputs");
        require(
            keccak256(bytes(users[msg.sender].name)) != keccak256(bytes("")),
            "Invalid user"
        );
        require(
            users[msg.sender].uType == UserTypes.MANUFACTURER,
            "Only manufacturer can add products"
        );

        Product memory _newProduct;
        _newProduct.name = name;
        _newProduct.pType = pType;
        _newProduct.manufacturer = msg.sender;
        _newProduct.manTime = manTime;
        _newProduct.quantity = quantity;
        _newProduct.price = price;
        _newProduct.currency = currency;

        uint _uid = random(manTime, name);
        require(
            products[_uid].manufacturer == address(0),
            "Duplicate product id, try again"
        );

        _newProduct.uId = _uid;
        products[_uid] = _newProduct;
        productUIds.push(_uid);

        // adding productId to user
        users[msg.sender].products.push(_uid);
        productCount.increment();

        // Adding a default transit
        Transit memory _newTransit;
        _newTransit.holder = msg.sender;
        _newTransit.transitType = TransitTypes.ARRIVAL;
        _newTransit.time = manTime;
        transits[_uid].push(_newTransit);

        // Adding it to recent transits
        recentTransits.push(_uid);
    }

    function getAllProducts() public view returns (Product[] memory) {
        // console.log("Getting all products from contract");
        Product[] memory _allProducts = new Product[](productCount.current());
        for (uint i = 0; i < productCount.current(); i++) {
            _allProducts[i] = products[productUIds[i]];
            // console.log("Product %d is %s", i, _allProducts[i].name);
        }

        return _allProducts;
    }

    function addArrival(uint productUId, uint time) public {
        // console.log("Adding new arrival");

        // geting last transit
        Transit memory _prevTransit;
        _prevTransit = transits[productUId][transits[productUId].length - 1];
        require(
            _prevTransit.transitType == TransitTypes.DEPARTURE,
            "The product must depart from the current holder"
        );
        require(
            _prevTransit.holder == msg.sender,
            "The product should arrive from the same previous holder"
        );

        Transit memory _newTransit;
        _newTransit.holder = msg.sender;
        _newTransit.time = time;
        _newTransit.transitType = TransitTypes.ARRIVAL;

        transits[productUId].push(_newTransit);
        recentTransits.push(productUId);
    }

    function addDeparture(
        uint productUId,
        uint time,
        address nextHolder
    ) public {
        // console.log("Adding new departure");

        // geting last transit
        Transit memory _prevTransit;
        _prevTransit = transits[productUId][transits[productUId].length - 1];
        require(
            _prevTransit.transitType == TransitTypes.ARRIVAL,
            "The product must arrive from the previous holder"
        );
        require(
            _prevTransit.holder != nextHolder,
            "The product cannot depart to the same previous holder"
        );

        Transit memory _newTransit;
        _newTransit.holder = nextHolder;
        _newTransit.time = time;
        _newTransit.transitType = TransitTypes.DEPARTURE;

        transits[productUId].push(_newTransit);
        recentTransits.push(productUId);

        // adding productId to user
        users[nextHolder].products.push(productUId);

        // adding holder details to product
        products[productUId].holders.push(nextHolder);
    }

    function getAllTransits(uint count)
        public
        view
        returns (ViewRecentTransit[] memory)
    {
        // console.log("Viewing last transits");

        // resetting count to available size
        if (count > recentTransits.length) count = recentTransits.length;

        // console.log("count %d", count);

        ViewRecentTransit[] memory _lastTransits = new ViewRecentTransit[](
            count
        );
        uint[] memory _tempRecentTransits = new uint[](count);
        uint _length;

        for (
            int i = int(recentTransits.length - 1);
            i >= int(recentTransits.length - count);
            i--
        ) {
            uint _uId = recentTransits[uint(i)];
            // console.log(_uId);
            uint _tempCount = 0;

            // find count of the same uid
            for (uint j = 0; j < _length; j++) {
                if (_tempRecentTransits[j] == _uId) _tempCount++;
            }

            _lastTransits[_length].uId = _uId;
            _lastTransits[_length].product = products[_uId];
            _lastTransits[_length].transit = transits[_uId][
                transits[_uId].length - 1 - _tempCount
            ];

            _tempRecentTransits[_length] = _uId;
            _length++;
        }

        return _lastTransits;
    }

    function getProduct(uint productUId)
        public
        view
        returns (ViewProduct memory)
    {
        require(
            products[productUId].manufacturer != address(0),
            "No such product"
        );

        Product memory _tempProduct = products[productUId];
        Transit[] memory _tempAllTransits = transits[productUId];

        ViewProduct memory _product;
        _product.uId = productUId;
        _product.product = _tempProduct;
        _product.allTransits = _tempAllTransits;

        return _product;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}