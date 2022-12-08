/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

// SPDX-License-Identifier: MIT
// File: Donations.sol



pragma solidity ^0.8.17;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        return a / b;
    }
}

interface IERC20 {
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

contract Donations {
    using SafeMath for uint;
    address public admin;
    address public VITreasury;
    uint256 public VIRoyalty;
    uint256 public minEthDonation = 0.001 ether;

    purchaseData[] allPurchases;
    rePurchaseData[] allRePurchases;

    mapping(address => purchaseData[]) userPurchases;
    mapping(address => rePurchaseData[]) userRePurchases;

    struct purchaseData {
        uint timestamp;
        address buyer;
        address beneficiary;
        uint donation;
    }

    struct rePurchaseData {
        uint timestamp;
        address buyer;
        address beneficiary;
        uint donation;
        address artist;
        uint artist_spercentage;
    }

    constructor(address _treasury) {
        admin = msg.sender;
        VITreasury = _treasury;
        VIRoyalty = 2;
    }

    modifier onlyOwner() {
        require(msg.sender == admin, "VINFTS: NOT AUTHORIZED");
        _;
    }

    // GETTER FUNCTIONS
    function getUserPurchases(address _doner) public view returns(purchaseData[] memory){
        return userPurchases[_doner];
    }

    function getUserRePurchases(address _doner) public view returns(rePurchaseData[] memory){
        return userRePurchases[_doner];
    }

    function getAllPurchases() public view returns(purchaseData[] memory) {
        return allPurchases;
    }

    function getAllRePurchases() public view returns(rePurchaseData[] memory){
        return allRePurchases;
    }


    // SETTER FUNCTIONS
    // function to change VINFTS treasury wallet;
    function changeTreasury(address _treasury) onlyOwner public {
        VITreasury = _treasury;
    }

    // function to change royalty sent to VITreasuty wallet;
    function changeRoyalty(uint _royalty) onlyOwner public {
        // if you want 2% percent, you should set "_royalty" to be 2;
        VIRoyalty = _royalty;
    }

    function purchaseToken(address _beneficiary, address _owner, uint _ownerPercentage) public payable {
        //uint _toBeneficiary = msg.value.mul(100-VIRoyalty-_ownerPercentage).div(100); // calculate amount will be sent to beneficiary;
        uint _toTreasury = msg.value.mul(VIRoyalty).div(100);
        uint _toBeneficiary = (msg.value-_toTreasury).mul(100-_ownerPercentage).div(100);
        uint _toOwner = (msg.value-_toTreasury).mul(_ownerPercentage).div(100);
        uint _transferCost = tx.gasprice.mul(2300); // calculate eth transfer cost;

        require(_toBeneficiary >= minEthDonation + _transferCost, "VINFTS: INSUFFICIENT AMOUNT FOR DONATION");

        payable(_beneficiary).transfer(_toBeneficiary);
        payable(VITreasury).transfer(_toTreasury);
        payable(_owner).transfer(_toOwner);


        _savePurchaseData(_beneficiary);
    }

    function _savePurchaseData(address _beneficiary) internal {
        purchaseData memory entry = purchaseData(
            block.timestamp,
            msg.sender,
            _beneficiary,
            msg.value
        );
        allPurchases.push(entry);
        userPurchases[msg.sender].push(entry);
    }

    function _saveRePurchaseData(address _beneficiary, address _owner, uint _ownerPercentage) internal {
        rePurchaseData memory entry = rePurchaseData(
            block.timestamp,
            msg.sender,
            _beneficiary,
            msg.value,
            _owner,
            _ownerPercentage
        );
        allRePurchases.push(entry);
        userRePurchases[msg.sender].push(entry);
    }

    function _isApproved(address _erc20, uint _amount) internal view returns(bool){
        uint _allowed = IERC20(_erc20).allowance(msg.sender, address(this));
        return _allowed >= _amount;
    }

    function _calcAmounts(uint _amount, uint _ownerPercentage) internal view returns(uint, uint, uint) {
        uint _toTreasury = _amount.mul(VIRoyalty).div(100);
        uint _toBeneficiary = (_amount-_toTreasury).mul(100-_ownerPercentage).div(100);
        uint _toOwner = (_amount-_toTreasury).mul(_ownerPercentage).div(100);

        return (
            _toTreasury,
            _toBeneficiary,
            _toOwner
        );
    }

    function puchraseTokenWithERC20(address _ERC20Address, uint _tokenAmount, address _beneficiary, address _owner, uint _ownerPercentage) public {
        bool isApproved = _isApproved(_ERC20Address, _tokenAmount);
        require(isApproved, "DONATIONS: NO ENOUGH TOKEN ALLOWANCE");
        (uint _toTreasury, uint _toBeneficiary, uint _toOwner) = _calcAmounts(_tokenAmount, _ownerPercentage);

        IERC20(_ERC20Address).transferFrom(msg.sender, VITreasury, _toTreasury);
        IERC20(_ERC20Address).transferFrom(msg.sender, _beneficiary, _toBeneficiary);
        IERC20(_ERC20Address).transferFrom(msg.sender, _owner, _toOwner);

        _savePurchaseData(_beneficiary);
    }

    function rePurchaseToken(address _beneficiary, address _owner, uint _ownerPercentage) public payable {
        //uint _toBeneficiary = msg.value.mul(100-VIRoyalty-_ownerPercentage).div(100); // calculate amount will be sent to beneficiary;
        (uint _toTreasury, uint _toBeneficiary, uint _toOwner) = _calcAmounts(msg.value, _ownerPercentage);
        uint _transferCost = tx.gasprice.mul(2300); // calculate eth transfer cost;
        
        require(_toBeneficiary >= minEthDonation + _transferCost, "VINFTS: INSUFFICIENT AMOUNT FOR DONATION");

        payable(_beneficiary).transfer(_toBeneficiary);
        payable(VITreasury).transfer(_toTreasury);
        payable(_owner).transfer(_toOwner);

        _saveRePurchaseData(_beneficiary, _owner, _ownerPercentage);
    }

    receive() external payable {

    }
}