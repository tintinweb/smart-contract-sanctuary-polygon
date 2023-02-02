// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IERC20.sol";
import "./Owner.sol";
import "./ReentrancyGuard.sol";

interface IERC1155{
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface Referrals{
    function addReward1(address _referredAccount, uint256 _amount) external returns(uint256);
    function addReward2(address _referredAccount, uint256 _amount) external returns(uint256);
}

contract SaleContract is Owner, ReentrancyGuard {

    address public payTokenAdress;
    address public nftsAddress;
    address public referrals;

    uint256[20] public saleTokenId; // TOKEN ID for sale
    uint256[20] public salePrice;   // sale price with decimals
    bool[20] public saleStatus;  // true = allow sale || false = locked sale
    uint256[20] public priceLvlx;   // sale price in LVLX with decimals (util for pay % referrals)

    mapping (address => bool) public inscriptionPay;
    uint256 public inscriptionAmount;

    event Set_InscriptionAmount(
        uint256 inscriptionAmount
    );

    event Set_TokenContracts(
        address payTokenAdress,
        address nftsAddress,
        address referrals
    );

    event Set_SaleType(
        uint256 index,
        uint256 indexed tokenId,
        uint256 price,
        bool status,
        uint256 priceLvlx
    );

    event successfulPurchase(
        uint256 indexed tokenId,
        uint256 price,
        uint256 amount,
        address indexed buyer
    );

    constructor(address _payTokenAdress, address _nftsAddress, address _referrals) {
        setTokenContracts(_payTokenAdress, _nftsAddress, _referrals);
        setSaleType(0, 1, 250000000, true, 2500000000000000000000);
        setSaleType(1, 2, 1250000000, true, 12500000000000000000000);
        setSaleType(2, 3, 5000000000, true, 50000000000000000000000);
        setInscriptionAmount(29000000);
    }

    function setInscriptionAmount(uint256 _inscriptionAmount) public isOwner {
        inscriptionAmount = _inscriptionAmount;
        emit Set_InscriptionAmount(_inscriptionAmount);
    }

    function setTokenContracts(address _payTokenAdress, address _nftsAddress, address _referrals) public isOwner {
        payTokenAdress = _payTokenAdress;
        nftsAddress = _nftsAddress;
        referrals = _referrals;
        emit Set_TokenContracts(_payTokenAdress, _nftsAddress, _referrals);
    }

    function setSaleType(uint256 _index, uint256 _tokenId, uint256 _price, bool _status, uint256 _priceLvlx) public isOwner {
        require(_index >= 0 && _index <= 19, "_index must be a number between 0 and 19");
        saleTokenId[_index] = _tokenId;
        salePrice[_index] = _price;
        saleStatus[_index] = _status;
        priceLvlx[_index] = _priceLvlx;
        emit Set_SaleType(_index, _tokenId, _price, _status, _priceLvlx);
    }

    function getSaleTypes() external view returns(uint256[] memory, uint256[] memory, bool[] memory) {
        uint256[] memory tokenIdList = new uint256[](saleTokenId.length);
        uint256[] memory priceList = new uint256[](saleTokenId.length);
        bool[] memory statusList = new bool[](saleTokenId.length);

        for (uint256 i=0; i<saleTokenId.length; i++) {
            tokenIdList[i] = saleTokenId[i];
            priceList[i] = salePrice[i];
            statusList[i] = saleStatus[i];
        }
        
        return (tokenIdList, priceList, statusList);
    }

    function buy(uint256 _saleIndex, uint256 _amount) external nonReentrant {
        require(saleStatus[_saleIndex], "sale type is locked");
        require(_amount>=1, "_amount must be greater than or equal to 1");
        
        uint256 amountToPay = _amount * salePrice[_saleIndex];
        if(!inscriptionPay[msg.sender]){
            inscriptionPay[msg.sender] = true;
            amountToPay += inscriptionAmount;
        }
        IERC20(payTokenAdress).transferFrom(msg.sender, getOwner(), amountToPay);

        IERC1155(nftsAddress).safeTransferFrom(
            getOwner(),
            msg.sender,
            saleTokenId[_saleIndex],
            _amount,
            ""
        );

        Referrals(referrals).addReward1(msg.sender, priceLvlx[_saleIndex]);
        emit successfulPurchase(saleTokenId[_saleIndex], salePrice[_saleIndex], _amount, msg.sender);
    }

}