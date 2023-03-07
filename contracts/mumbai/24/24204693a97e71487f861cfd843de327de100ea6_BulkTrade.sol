pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract BulkTrade is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 private tradeTokenContract;
    uint256 private tradeTokenAmount;
    
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event TradeBasic(address indexed _account, address _tradeTokenContract, uint256 _tradeTokenAmount);

    // ================= Value ===============

    constructor () public {
          tradeTokenContract = ERC20(0x9557985D1684ac43226dEcB72841114eacb8fB9C);
          tradeTokenAmount = 1 * 10 ** 18; // 1 coin
    }

    function tradeErc20Token(address[] memory _to) public returns (bool) {

        // Data validation
        require(_to.length>0,"-> _to: length is 0.");
        require(tradeTokenContract.balanceOf(address(msg.sender))>_to.length.mul(tradeTokenAmount),"-> token balance: Insufficient number of tokens.");

        for(uint32 i=0;i<_to.length;i++){
            tradeTokenContract.safeTransferFrom(address(msg.sender), _to[i], tradeTokenAmount);// Transfer mac to airdrop address
        }
        return true;// return result
    }

    // ================= Contact Query  =====================

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer wiki to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    function getTradeBasic() public view returns (ERC20 TradeTokenContract,uint256 TradeTokenAmount) {
        return (tradeTokenContract,tradeTokenAmount);
    }

    // ================= Contact Operation  =====================

    function setTradeBasic(address _tradeTokenContract,uint256 _tradeTokenAmount) public onlyOwner returns (bool) {
        tradeTokenContract = ERC20(_tradeTokenContract);
        tradeTokenAmount = _tradeTokenAmount; // 1 coin
        emit TradeBasic(msg.sender, _tradeTokenContract, _tradeTokenAmount);
        return true;
    }

}