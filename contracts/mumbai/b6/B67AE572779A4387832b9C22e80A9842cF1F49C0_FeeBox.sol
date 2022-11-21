//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

interface IDava {
    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOf(address owner) external view returns (uint256);
}

contract FeeBox {
    IERC20 constant ethContract =
        IERC20(0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa);
    IDava constant davaContract =
        IDava(0x68B473060e753052DC8DE49b668AD03276566FC6);
    // uint256 constant timeWindow = 7 days;
    uint256 constant timeWindow = 5 minutes;
    uint256 constant _baseDealerBonusPoints = 10;
    uint256 constant _basePoints = 5000; // 50%
    uint256 private _lastDistributedAt = 0;

    constructor() {
        _lastDistributedAt = block.timestamp;
    }

    receive() external payable {}

    function _checkEthBalance() private view returns (uint256) {
        return ethContract.balanceOf(address(this));
    }

    function _checkMaticBalance() private view returns (uint256) {
        return address(this).balance;
    }

    function isReadyToWheel() public view returns (bool) {
        return block.timestamp > _lastDistributedAt + timeWindow;
    }

    function wheelRoulette() external {
        require(isReadyToWheel(), "FeeBox: not ready to wheel");

        uint256 dealerBonusPoints;
        uint256 balanceOfDealer = davaContract.balanceOf(msg.sender);
        if (balanceOfDealer == 0) dealerBonusPoints = _baseDealerBonusPoints;
        else dealerBonusPoints = (balanceOfDealer * _basePoints) / 10000;

        uint256 mod = 10000 + dealerBonusPoints;
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        ) % mod;

        address payable beneficiary = payable(0);
        if (randomNumber >= 10000) beneficiary = payable(msg.sender);
        while (beneficiary == address(0)) {
            address ownerOfDava = _checkOwner(randomNumber);
            if (ownerOfDava == address(0))
                randomNumber = (randomNumber + 1) % mod;
            else beneficiary = payable(ownerOfDava);
        }

        uint256 wethBalance = _checkEthBalance();
        if (wethBalance > 0) {
            bool sent = ethContract.transfer(beneficiary, wethBalance);
            require(sent, "FeeBox: failed to send weth");
        }

        uint256 maticBalance = _checkMaticBalance();
        if (maticBalance > 0) {
            (bool sent, ) = beneficiary.call{value: maticBalance}("");
            require(sent, "FeeBox: failed to send matic");
        }

        _lastDistributedAt = block.timestamp;
    }

    function _checkOwner(uint256 _tokenId) private view returns (address) {
        try davaContract.ownerOf(_tokenId) returns (address owner) {
            return owner;
        } catch {
            return address(0);
        }
    }
}