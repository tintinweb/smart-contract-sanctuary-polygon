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
        uint256 confirmationCount;
        uint256 confirmationTimestamp;
    }

    constructor() payable {}

    Will public will;

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

    function sendConfirmation() external checkActivated {

        if (will.confirmationCount >= 5) {
            activateWill();
        } else {
            uint256 lastConfirmationTime = will.confirmationTimestamp;

            // Thời gian giữa 2 lần xác nhận is 356 days
            uint256 confirmationInterval = 0 seconds;

            if (
                block.timestamp >= lastConfirmationTime + confirmationInterval
            ) {
                // Cập nhật lại thời điểm xác nhận
                will.confirmationTimestamp = block.timestamp;
                will.confirmationCount++;

                emit ConfirmationRequestSent(msg.sender, block.timestamp);
            }
        }
    }

    function acceptConfirmationLife() external checkActivated {
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

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit() public payable {
        //check sender's will
        will.assetAmount += msg.value;
    }
}