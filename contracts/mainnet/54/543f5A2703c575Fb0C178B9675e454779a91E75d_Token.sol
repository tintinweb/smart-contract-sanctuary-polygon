/**
 *Submitted for verification at polygonscan.com on 2022-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*
INHERITANCE CLASSES
*/


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}


library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}



contract Token is Context, Ownable {
    using Address for address;

    mapping(address => uint) public balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

/*
TOKEN INFO
*/

    uint public _totalSupply = 500000000000 * 10 ** 18;
    uint public _decimals = 18;
    string public _name = "BOO Coin"; 
    string public _symbol = "BOO";

    address payable public taxAddress = payable(0xf97260eEf0727D9a20d2538b816f1722180E7967); 
    address payable public rewardsAddress = payable(0xaaa6e97Fc3cfe0376Ffcb18C35FC1757469c539E); 
    address public contractAddress = address(this);
    

    uint public reflectionsFee = 4; //4%
    uint public taxFee = 2; //2%

    uint public previousTaxFee=taxFee;
    uint public previousreflectionsFee=reflectionsFee;
   

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[0xf97260eEf0727D9a20d2538b816f1722180E7967] = _totalSupply - 108000000 * 10 ** 18;
        balances[0xaaa6e97Fc3cfe0376Ffcb18C35FC1757469c539E] = 108000000 * 10 ** 18;
        _isExcludedFromFee[taxAddress] = true;
        _isExcludedFromFee[rewardsAddress] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

    }



/*
GENERAL FUNCTIONS
*/



    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address value) public returns(uint256) {
        return balances[value];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function reflectionsBalance() public view returns (uint256) {
        return balances[address(this)];
    }

    function rewardsBalance() public view returns (uint256){
        return balances[rewardsAddress];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function totalFees() public view returns (uint256) {
        return reflectionsFee+taxFee;
    }



/*
TRANSFER FUNCTIONS
*/


    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
            require(_allowances[sender][_msgSender()] >= amount, "transfer amount exceeds allowance");
            _transfer(sender, recipient, amount);
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()]-amount);
            return true;
    }


    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {

        uint256 taxAmount;
        uint256 reflectionsAmount;

        if(!takeFee) {

            taxAmount = 0;
            reflectionsAmount = 0;

            balances[sender]-=(amount);
            balances[recipient]+=(amount);

            emit Transfer(sender, recipient, amount);

        }

        else {

            taxAmount = calculateTaxFee(amount);
            reflectionsAmount = calculateReflectionsFee(amount);


            balances[sender]-=(amount);

            balances[taxAddress]+=(taxAmount);
            balances[address(this)]+=(reflectionsAmount);

            balances[recipient]+=(amount-taxAmount-reflectionsAmount);

            emit Transfer(sender, recipient, amount);

        }   
    }
    


/*
CALCULATE FEES 
*/

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount*(taxFee)/(100);
    }

    function calculateReflectionsFee(uint256 _amount) private view returns (uint256) {
        return _amount*(reflectionsFee)/(100);
    }


/*
INCLUDE AND EXCLUDE FROM FEES FUNCTIONS
*/

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    


/*
ONLYOWNER EDIT CONTRACT FUNCTIONS
*/

    function setTaxAddress(address _taxAddress) external onlyOwner() {
        taxAddress = payable(_taxAddress);
    }

    function setRewardsAddress(address _rewardsAddress) external onlyOwner() {
        rewardsAddress = payable(_rewardsAddress);
    }

    function setTaxFeePercent(uint256 _taxFee) external onlyOwner() {
        require(_taxFee >= 0, 'Fee Too Low');
        require(_taxFee <= 5, 'Fee Too High');
        taxFee = _taxFee;     
    }

    function setReflectionsFee(uint256 _reflectionsFee) external onlyOwner() {  
        require(_reflectionsFee >= 0, 'Reflections Too Low');
        require(_reflectionsFee <= 5, 'Reflections Too High');
        reflectionsFee = _reflectionsFee;           
    }

    function deactivateAllFees() external onlyOwner() {  
        
        previousTaxFee = taxFee;
        previousreflectionsFee = reflectionsFee;

        reflectionsFee = 0;
        taxFee = 0;      
    }

    function activateAllFees() external onlyOwner() {  
        reflectionsFee = previousreflectionsFee;
        taxFee = previousTaxFee;       
    }

    function hardBurnFromOwner(uint256 _amount) external onlyOwner() {
        require(balanceOf(owner()) >= _amount, "not enough tokens to burn");
        _totalSupply -=_amount;
        balances[owner()]-=(_amount);
    }

/* 
REFLECTIONS AND REWARDS DISTRIBUTION
*/

    function triggerReflections(address[] calldata recipients) internal onlyOwner(){
        uint256 _amount = reflectionsBalance()/recipients.length;

      for (uint256 i = 0; i < recipients.length; i++) {
        balances[address(this)]-=(_amount);
        balances[recipients[i]]+=(_amount);
      }

    }

    function sendRewards(uint256 distributionAmount, address[] calldata recipients) external onlyOwner(){ 
        require(balanceOf(rewardsAddress) >= distributionAmount, "not enough tokens on the rewards address");
        balances[rewardsAddress]-=(distributionAmount);
        balances[address(this)]+=(distributionAmount);
        triggerReflections(recipients);
    }

}