// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract Testament {
    struct Will {
        address testator; // Người viết di chúc
        uint256 creationTimestamp; // Thời điểm tạo di chúc
        uint256 assetAmount; // Số lượng tài sản trong di chúc
        address[] beneficiaries; // Danh sách người thừa kế
        uint256[] allocationPercentages; // ti le phan bo
        bool activated; // Trạng thái kích hoạt của di chúc
        uint8 confirmationCount;
        uint256 lastConfirmationTimestamp;
    }
    Will private will;

    // address private owner;

    constructor(address _owner) {
        will.testator = _owner;
    }

    event ConfirmationRequestSent(
        address indexed testator,
        uint256 confirmationTime
    );

    event WillCreated(address indexed testator, uint256 creationTimestamp);
    event WillActivated(address indexed testator);
    event ConfirmationRequestAccepted(address indexed testator);
    event MoneyTransferred(address receiver, uint256 amount);

    function create(
        address[] memory _beneficiaries,
        uint256[] memory _allocationPercentages
    ) external payable {
        require(
            _beneficiaries.length == _allocationPercentages.length,
            "Beneficiaries and percentages must have the same length"
        );
        require(
            _beneficiaries.length > 0,
            "At least one beneficiary must be specified"
        );

        will = Will(
            msg.sender,
            block.timestamp,
            msg.value,
            _beneficiaries,
            _allocationPercentages,
            false,
            0,
            block.timestamp
        );

        emit WillCreated(msg.sender, block.timestamp);
    }

    function getAllBeneficiaries() public view returns (address[] memory) {
        return will.beneficiaries;
    }

    function getAllocationPercentages() public view returns (uint256[] memory) {
        return will.allocationPercentages;
    }

    function activateWill() internal {
        will.activated = true;

        // Phân phối tài sản cho người thừa kế
        distributeAssets();

        emit WillActivated(msg.sender);
    }

    modifier checkActivated() {
        require(!will.activated, "Will activated");
        _;
    }

    modifier checkOwner() {
        require(will.testator == msg.sender, "Not owner");
        _;
    }

    function sendConfirmation() external checkActivated {
        if (will.confirmationCount >= 5) {
            activateWill();
        } else {
            uint256 lastConfirmationTime = will.lastConfirmationTimestamp;

            // Thời gian giữa 2 lần xác nhận is 356 days
            uint256 confirmationInterval = 0 seconds;

            if (
                block.timestamp >= lastConfirmationTime + confirmationInterval
            ) {
                // Cập nhật lại thời điểm xác nhận
                will.lastConfirmationTimestamp = block.timestamp;
                will.confirmationCount++;

                emit ConfirmationRequestSent(msg.sender, block.timestamp);
            }
        }
    }

    function acceptConfirmationLife() external checkActivated checkOwner {
        will.confirmationCount--;

        // Kiểm tra nếu đạt ngưỡng kích hoạt
        if (will.confirmationCount >= 5) {
            activateWill();
        } else {
            will.confirmationCount = 0;
        }

        emit ConfirmationRequestAccepted(msg.sender);
    }

    function distributeAssets() private {
        uint256 totalAssetAmount = will.assetAmount;
        address[] memory beneficiaries = will.beneficiaries;
        uint256[] memory allocationPercentages = will.allocationPercentages;
        uint256 beneficiariesSize = beneficiaries.length;

        for (uint256 i = 0; i < beneficiariesSize; i++) {
            address beneficiary = beneficiaries[i];
            uint256 allocationPercentage = allocationPercentages[i];
            uint256 beneficiaryAmount = (totalAssetAmount *
                allocationPercentage) / 100;

            transferTo(beneficiary, beneficiaryAmount);
        }
    }

    function transferTo(address _recipient, uint256 amount) private {
        payable(_recipient).transfer(amount);
        emit MoneyTransferred(_recipient, amount);
    }

    function getAssetAmount() public view checkOwner returns (uint256) {
        return will.assetAmount;
    }

    function deposit() public payable checkOwner {
        //check sender's will
        will.assetAmount += msg.value;
    }

    function getConfirmationCount() public view checkOwner returns (uint8) {
        return will.confirmationCount;
    }

    function getConfirmationTimestamp()
    public
    view
    checkOwner
    returns (uint256)
    {
        return will.lastConfirmationTimestamp;
    }

    function getTestator() public view checkOwner returns (address) {
        return will.testator;
    }

    function getStatusWill() public view checkOwner returns (bool) {
        return will.activated;
    }

    function withdraw(uint256 amount) public checkOwner {
        require(will.assetAmount >= amount, "Insufficient balance");

        will.assetAmount -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}