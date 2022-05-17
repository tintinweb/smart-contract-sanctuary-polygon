// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract airDropCt is AccessControl{

    /* ========== STATE VARIABLES ========== */
    address public  contractAdr;
    uint256 public airDropAmt;
    address[] public arrayAddress = [0x324D49549b27d8a7B5746c0D633DBA966723f917,0x9d14857110fF9C8A97495C0F09Ed9D69E320Ef9b];

    /* ========== MAPPING VARIABLES ========== */
    mapping (address => bool) accountAirDrop;

    /* ========== MODIFIER ========== */
    modifier onlyAdmin (){
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }
    modifier airDropCheck (address _account){
        require(accountAirDrop[_account] == false, "Caller is not an admin");
        _;
    }

    event airDropEvt(address indexed Account,uint256 Amount, address claimBy);

    /* ========== CONSTRUCTOR ========== */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /* ========== ADMIN FUNCTIONS ========== */
    function setContract(address _contractAdr,uint256 _airDropAmt) public onlyAdmin{
        airDropAmt = _airDropAmt;
        contractAdr = _contractAdr;
    }

    function checkApprove(address _account) public view returns (uint256 _amt){
        IERC20 Token = IERC20(contractAdr);
        return Token.allowance(_account,address(this));
    }

    function airDrop(address[] memory _accounts)  public onlyAdmin returns (bool status)  {
        for(uint256 i = 0; i < _accounts.length; i++){
            if(accountAirDrop[_accounts[i]]  == false){
                airDropSingle(_accounts[i]);
            }
        }
        return true;
    }

    function airDropArray()  public onlyAdmin returns (bool status)  {
        for(uint256 i = 0; i < arrayAddress.length; i++){
            if(accountAirDrop[arrayAddress[i]]  == false){
                airDropSingle(arrayAddress[i]);
            }
        }
        return true;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    function airDropSingle(address _accounts)public airDropCheck(_accounts) returns (bool status) {
        IERC20 Token = IERC20(contractAdr);
        accountAirDrop[_accounts] = true;
        Token.transfer(_accounts,airDropAmt);
        emit airDropEvt(_accounts,airDropAmt, msg.sender);
        return true;
    }

    function approveContract(uint _amt) public {
        IERC20 Token = IERC20(contractAdr);
        Token.approve(address(this), _amt);
    }

}