/**
 *Submitted for verification at polygonscan.com on 2022-05-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract CrunchTokenSales {

    bool public checkSaleStatus;
    address public crunchToken;
    address public USDT;
    address public USDC;

    address public owner;
    uint256 public totalAmountSoldOut;
    uint256 public Price;

    event sales(address token, address indexed to, uint256 amountIn, uint256 amountRecieved);
    // event Whitelist(address indexed userAddress, bool Status);

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    // Only allow the owner to do specific tasks
    modifier onlyOwner() {
        require(_msgSender() == owner,"TIKI TOKEN: YOU ARE NOT THE OWNER.");
        _;
    }

    constructor( address _crunchtoken, address _usdt, address _usdc, uint256 _price) {
        owner =  _msgSender();
        checkSaleStatus = true;
        crunchToken = _crunchtoken;
        USDT = _usdt;
        USDC = _usdc;
        Price = _price;
    }

    function buy(uint256 _tokenAmount, address purchaseWith) public {
        require(checkSaleStatus == true, "CRUNCH NETWORK: SALE HAS ENDED.");
        require(_tokenAmount ** IERC20(purchaseWith).decimals() > 0, "CRUNCH NETWORK: BUY ATLEAST 1 TOKEN.");
        require(purchaseWith == USDT || purchaseWith == USDC, "Invalid Token Contract");
        uint256 reward = calculateReward(_tokenAmount);
        uint256 addressBalance = IERC20(crunchToken).balanceOf(address(this));
        require(addressBalance >= reward, "CRUNCH NETWORK: Contract Balance too low for amount provided");
        require(IERC20(purchaseWith).transferFrom(_msgSender(), address(this), _tokenAmount ** IERC20(purchaseWith).decimals()), "CRUNCH NETWORK: TRANSFERFROM FAILED!");

        totalAmountSoldOut += _tokenAmount * 10 ** IERC20(purchaseWith).decimals();
        IERC20(crunchToken).transfer(_msgSender(), reward);

        emit sales(purchaseWith, _msgSender(), _tokenAmount, reward);
    }

    function calculateReward(uint256 amount) public view returns(uint256) {
        uint256 p = Price;
        uint256 reward = (amount * 10 ** IERC20(crunchToken).decimals() / p) * 10 ** IERC20(crunchToken).decimals();
        return reward ;
    }

    function resetPrice(uint256 newPrice) external onlyOwner {
        Price = newPrice;
    }
    
    // To enable the sale, send RGP tokens to this contract
    function enableSale(bool status) external onlyOwner{

        // Enable the sale
        checkSaleStatus = status;
    }

    // Withdraw (accidentally) to the contract sent eth
    function withdrawBNB() external payable onlyOwner {
        payable(owner).transfer(payable(address(this)).balance);
    }

    // Withdraw (accidentally) to the contract sent ERC20 tokens
    function withdrawToken(address _token) external onlyOwner {
        uint _tokenBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner, _tokenBalance);
    }
}