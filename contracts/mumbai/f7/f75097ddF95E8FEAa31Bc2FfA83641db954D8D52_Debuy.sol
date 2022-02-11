//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDebuy.sol";

contract Debuy is IDebuy {
    uint256 constant DEPOSIT_MULTIPLIER = 2000;
    uint256 constant DEPOSIT_DENOMINATOR = 1000;
    uint256 constant ACTIVITY_TIMEOUT = 100 days;
    uint256 public indexCounter;

    Advert[] public adverts;
    mapping(address => uint256) public lastActivity;

    function updateActivity() public {
        lastActivity[msg.sender] = block.timestamp;
    }

    // if _buyer set to zero address then anyone could apply to this advert
    // TODO add check that both addresses could accept ether
    function createAdvert(
        uint256 _price,
        string calldata _title,
        string calldata _description,
        string calldata _region,
        string calldata _ipfs,
        address _buyer
    ) external payable override returns (uint256 index) {
        Status status = Status.Created;
        if (msg.value > 0) {
            require(
                msg.value ==
                    (_price * DEPOSIT_MULTIPLIER) / DEPOSIT_DENOMINATOR,
                "Wrong deposit value."
            );
            status = Status.SellerBacked;
        }
        adverts.push(
            Advert({
                createdAt: block.timestamp,
                status: status,
                price: _price,
                title: _title,
                description: _description,
                region: _region,
                ipfs: _ipfs,
                seller: msg.sender,
                buyer: _buyer,
                sellerRatio: DEPOSIT_MULTIPLIER,
                buyerRatio: DEPOSIT_MULTIPLIER
            })
        );

        // TODO emit event of creation
        updateActivity();
        indexCounter++;
        return indexCounter - 1;
    }

    function applyToAdvert(uint256 _id) external payable {
        if (msg.sender == adverts[_id].seller) {
            applyToAdvertBySeller(_id);
        } else if (
            msg.sender == adverts[_id].buyer || adverts[_id].buyer == address(0)
        ) {
            applyToAdvertByBuyer(_id);
        } else {
            revert("You can't applie to this advert.");
        }
    }

    function applyToAdvertBySeller(uint256 _id) private {
        // require(
        //     msg.sender == adverts[_id].seller,
        //     "You are not a seller of this advert."
        // );
        require(
            msg.value ==
                (adverts[_id].price * adverts[_id].sellerRatio) /
                    DEPOSIT_DENOMINATOR,
            "Wrong deposit value."
        );
        if (adverts[_id].status == Status.Created) {
            adverts[_id].status = Status.SellerBacked;
            // TODO emit event of seller backed
        } else if (adverts[_id].status == Status.BuyerBacked) {
            adverts[_id].status = Status.Active;
            // TODO emit event of active
        } else {
            revert("Already applied.");
        }

        updateActivity();
    }

    // TODO add check that buyer address could accept ether
    function applyToAdvertByBuyer(uint256 _id) private {
        // require(
        //     msg.sender == adverts[_id].buyer ||
        //         adverts[_id].buyer == address(0),
        //     "You can't applie to this advert."
        // );
        require(
            msg.value ==
                (adverts[_id].price * adverts[_id].buyerRatio) /
                    DEPOSIT_DENOMINATOR,
            "Wrong deposit value."
        );
        if (adverts[_id].status == Status.Created) {
            adverts[_id].status = Status.BuyerBacked;
            // TODO emit event of seller backed
        } else if (adverts[_id].status == Status.SellerBacked) {
            adverts[_id].status = Status.Active;
            // TODO emit event of active
        } else {
            revert("Already applied.");
        }
        adverts[_id].buyer = msg.sender;

        updateActivity();
    }

    function forceClose(uint256 _id) external {
        require(adverts[_id].status == Status.Active, "Advert is not active.");

        uint256 lastActive;

        if (msg.sender == adverts[_id].seller) {
            lastActive = lastActivity[adverts[_id].buyer];
        } else if (msg.sender == adverts[_id].buyer) {
            lastActive = lastActivity[adverts[_id].seller];
        } else {
            revert("You are not a part of this advert.");
        }

        require(
            block.timestamp > lastActive + ACTIVITY_TIMEOUT,
            "Activity timeout not reached."
        );

        adverts[_id].status = Status.ForceClosed;

        uint256 value = (adverts[_id].price *
            adverts[_id].sellerRatio +
            adverts[_id].price *
            adverts[_id].buyerRatio) / DEPOSIT_DENOMINATOR;
        (bool sent, ) = msg.sender.call{value: value}("");
        require(sent, "Failed to send Ether");

        // TODO emit event of forceClose
        updateActivity();
    }

    function confirmClose(uint256 _id) external {
        require(msg.sender == adverts[_id].buyer, "You are not a buyer.");
        require(adverts[_id].status == Status.Active, "Advert is not active.");

        adverts[_id].status = Status.Finished;

        uint256 value = (adverts[_id].price * adverts[_id].sellerRatio) /
            DEPOSIT_DENOMINATOR +
            adverts[_id].price;
        (bool sent, ) = adverts[_id].seller.call{value: value}("");
        require(sent, "Failed to send Ether");

        value =
            (adverts[_id].price * adverts[_id].buyerRatio) /
            DEPOSIT_DENOMINATOR -
            adverts[_id].price;
        (sent, ) = adverts[_id].buyer.call{value: value}("");
        require(sent, "Failed to send Ether");

        // TODO emit event of Finished

        updateActivity();
    }

    function updateBuyer(uint256 _id, address _newBuyer) external {
        require(msg.sender == adverts[_id].seller, "You are not a seller.");

        if (adverts[_id].status == Status.BuyerBacked) {
            adverts[_id].status = Status.Created;

            uint256 value = (adverts[_id].price * adverts[_id].buyerRatio) /
                DEPOSIT_DENOMINATOR;
            (bool sent, ) = adverts[_id].buyer.call{value: value}("");
            require(sent, "Failed to send Ether");

            adverts[_id].buyer = _newBuyer;
        } else if (
            adverts[_id].status == Status.SellerBacked ||
            adverts[_id].status == Status.Created
        ) {
            adverts[_id].buyer = _newBuyer;
        } else {
            revert("Advert can't be updated.");
        }

        // TODO emit event buyer updated

        updateActivity();
    }

    modifier onlySellerOnCreated(uint256 _id) {
        require(msg.sender == adverts[_id].seller, "You are not a seller.");
        require(
            adverts[_id].status == Status.Created,
            "Only empty advert could be updated."
        );
        _;
    }

    function updatePrice(uint256 _id, uint256 _newPrice)
        external
        onlySellerOnCreated(_id)
    {
        adverts[_id].price = _newPrice;
        // TODO emit updated price ?
    }

    function updateTitle(uint256 _id, string calldata _newTitle)
        external
        onlySellerOnCreated(_id)
    {
        adverts[_id].title = _newTitle;
        // TODO emit updated title ?
    }

    function updateDescription(uint256 _id, string calldata _newDescription)
        external
        onlySellerOnCreated(_id)
    {
        adverts[_id].description = _newDescription;
        // TODO emit updated description ?
    }

    function updateIpfs(uint256 _id, string calldata _newIpfs)
        external
        onlySellerOnCreated(_id)
    {
        adverts[_id].ipfs = _newIpfs;
        // TODO emit updated ipfs ?
    }

    function updateRegion(uint256 _id, string calldata _newRegion)
        external
        onlySellerOnCreated(_id)
    {
        adverts[_id].region = _newRegion;
        // TODO emit updated region ?
    }

    function withdraw(uint256 _id) external {
        require(
            adverts[_id].status == Status.BuyerBacked ||
                adverts[_id].status == Status.SellerBacked,
            "Can't withdraw from this advert."
        );
        if (msg.sender == adverts[_id].buyer) {
            adverts[_id].status = Status.Created;

            uint256 value = (adverts[_id].price * adverts[_id].buyerRatio) /
                DEPOSIT_DENOMINATOR;
            (bool sent, ) = adverts[_id].buyer.call{value: value}("");
            require(sent, "Failed to send Ether");
        } else if (msg.sender == adverts[_id].seller) {
            adverts[_id].status = Status.Created;

            uint256 value = (adverts[_id].price * adverts[_id].sellerRatio) /
                DEPOSIT_DENOMINATOR;
            (bool sent, ) = adverts[_id].seller.call{value: value}("");
            require(sent, "Failed to send Ether");
        } else {
            revert("You are not a part of this advert.");
        }
        // TODO emit withdrawed deposit ?
    }

    function decreaseSellerRatio(uint256 _id, uint256 _newRatio) external {
        require(msg.sender == adverts[_id].seller, "You are not a seller.");
        require(
            adverts[_id].status == Status.Active,
            "Advert should be active to update ratio."
        );
        require(
            _newRatio < adverts[_id].sellerRatio,
            "Seller ratio could be only decreased."
        );
        uint256 diff = adverts[_id].sellerRatio - _newRatio;
        adverts[_id].sellerRatio -= diff;
        adverts[_id].buyerRatio += diff;

        // TODO emit ratio decreased ?
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDebuy {
    enum Status {
        Created,
        SellerBacked,
        BuyerBacked,
        Active,
        ForceClosed,
        Finished
    }

    struct Advert {
        uint256 createdAt;
        Status status;
        uint256 price;
        string title;
        string description;
        string region;
        string ipfs;
        address seller;
        address buyer;
        uint256 sellerRatio;
        uint256 buyerRatio;
    }

    function createAdvert(
        uint256 _price,
        string calldata _title,
        string calldata _description,
        string calldata _region,
        string calldata _ipfs,
        address _buyer
    ) external payable returns (uint256 index);

    // TODO add functions and events
}