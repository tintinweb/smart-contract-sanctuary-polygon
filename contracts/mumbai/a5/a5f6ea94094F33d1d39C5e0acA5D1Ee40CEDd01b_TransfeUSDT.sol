/**
 *Submitted for verification at polygonscan.com on 2023-05-02
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.19;

interface BEP20 {

  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TransfeUSDT {

    address public owner;
    address public USDT;

    address[4] private wallets;
    uint256[4] private walletPercentages;

    event NewWallets(address Caller, address Wallet1, address Wallet2, address Wallet3, address Wallet4);
    event NewFeePercentage(address Caller,uint Fee1, uint Fee2, uint Fee3, uint Fee4);
    event USDTTransfer(address indexed caller, uint Amount1, uint Amount2, uint Amount3, uint Amount4);

    constructor(address _USDT) {
        owner = msg.sender;
        USDT = _USDT;

        wallets = [0x01f09AAa325053d70D5244DdfC1FbA12e11a4aCA,0x01f09AAa325053d70D5244DdfC1FbA12e11a4aCA,0x01f09AAa325053d70D5244DdfC1FbA12e11a4aCA,0x01f09AAa325053d70D5244DdfC1FbA12e11a4aCA];  
        walletPercentages = [9,11,8,972];      
    }


    modifier onlyOwner {
        require(owner == msg.sender,"caller is not the owner");
        _;
    }

    function transferUSDT(uint _amount) external {
        (uint share1, uint share2, uint share3, uint share4) = calculateFee( _amount);
        BEP20(USDT).transferFrom(msg.sender, address(this), _amount);
        
        //transfer to wallets
        BEP20(USDT).transfer(wallets[0], share1);
        BEP20(USDT).transfer(wallets[1], share2);
        BEP20(USDT).transfer(wallets[2], share3);
         BEP20(USDT).transfer(wallets[3], share4);

        emit USDTTransfer(msg.sender, share1,share2,share3,share4);
    }

    function calculateFee(uint _amount) public view returns(uint share1, uint share2, uint share3, uint share4){
        share1 = _amount*(walletPercentages[0])/(1e3);
        share2 = _amount*(walletPercentages[1])/(1e3);
        share3 = _amount*(walletPercentages[2])/(1e3);
        share4 = _amount*(walletPercentages[3])/(1e3);

    }

    function viewWallets() external view returns(address wallet1, address wallet2, address wallet3, address wallet4) {
        return (wallets[0],wallets[1],wallets[2],wallets[3]);
    }

    function viewWalletPercentage() external view returns(uint Percentage1, uint Percentage2, uint Percentage3, uint Percentage4) {
        return (walletPercentages[0], walletPercentages[1], walletPercentages[2], walletPercentages[3]);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setWallet(address _wallet1, address _wallet2, address _wallet3, address _wallet4) external onlyOwner {
        require(_wallet1 != address(0x0) && _wallet2 != address(0x0) && _wallet3 != address(0x0) && _wallet4 != address(0x0), "Zero address appears");
        wallets = [_wallet1, _wallet2, _wallet3, _wallet4];

        emit NewWallets(msg.sender, _wallet1, _wallet2, _wallet3, _wallet4);
    }

    function setWalletFees(uint256 _fee1, uint256 _fee2, uint256 _fee3, uint256 _fee4) external onlyOwner {
        require(_fee1 + _fee2 + _fee3 + _fee4 == 1000,"Invalid fee amount");
        walletPercentages = [ _fee1, _fee2, _fee3, _fee4];
        emit NewFeePercentage(msg.sender, _fee1, _fee2, _fee3, _fee4);
    }

    function setUSDT(address _USDT) external onlyOwner {
        require(_USDT != address(0x0) , "Zero address appears");
        USDT = _USDT;
    }
    
    function recover(address _tokenAddres, address _to, uint _amount) external onlyOwner {
        if(_tokenAddres == address(0x0)){
            require(payable(_to).send(_amount),"");
        } else {
            BEP20(_tokenAddres).transfer( _to, _amount);
        }
    }

}