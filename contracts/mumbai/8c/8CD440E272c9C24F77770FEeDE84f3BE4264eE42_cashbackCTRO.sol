/**
 *Submitted for verification at polygonscan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ERC20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Address {
   
    function isContract(address account) internal view returns (bool) {
        
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

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

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

     function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract SafeERC20 {
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(ERC20 token, bytes memory data) private {
       

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Pausable is Context {
    
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        require(!_paused,"already Paused");
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        require(_paused,"already Paused");
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract cashbackCTRO is Ownable, ReentrancyGuard, Pausable, SafeERC20{

    ERC20 public CTROStoken;
    ERC20 public CTROtoken;
    address public comercioWallet;
    uint32 public offerPercentage = 50; // 10 => 1%
    uint32[3] public sharePercentage = [1000,0,0];


    event DepositCTRO(address indexed User, uint256 TokenAmount, uint256 CTROReward, uint256 Time);
    event RecoverTokens(address indexed Receiver, address indexed tokenAddress, uint256 TokenAmount);

    constructor(address[3] memory _tokens_wallets) {
        CTROStoken = ERC20(_tokens_wallets[0]);
        CTROtoken = ERC20(_tokens_wallets[1]);

        comercioWallet = _tokens_wallets[2];
    }

    function pause() external onlyOwner{
        _pause();
    }

    function unPause() external onlyOwner{
        _unpause();
    }

    function deposit(uint256 _tokenAmount) external whenNotPaused nonReentrant {

        uint256 rewardAmount = _tokenAmount * offerPercentage / 1e3;

        safeTransferFrom(CTROtoken, _msgSender(), address(this), _tokenAmount);

        safeTransfer(CTROtoken, comercioWallet, _tokenAmount);

        safeTransfer(CTROStoken, _msgSender(), rewardAmount);

        emit DepositCTRO(_msgSender(), _tokenAmount, rewardAmount, block.timestamp);

    }

    function updateOfferPercentage(uint32 _percentage) external onlyOwner {
        offerPercentage = _percentage;
    }

    function updatecomercioWallet(address _comercioWallet) external onlyOwner{
        require(_comercioWallet != address(0), "Invalid wallet.");
        comercioWallet = _comercioWallet;
    }

    function updateCTROtoken(address _CTRO) external onlyOwner {
        require(_CTRO != address(0) && ERC20(_CTRO) != CTROtoken, "Invalid CTRO address");
        CTROtoken = ERC20(_CTRO);
    }

    function updateCTROStoken(address _CTRO) external onlyOwner {
        require(_CTRO != address(0) && ERC20(_CTRO) != CTROStoken, "Invalid CTRO address");
        CTROStoken = ERC20(_CTRO);
    }

    function recoverTokens(address _to,address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(ERC20(_tokenAddress).balanceOf(address(this)) >= _tokenAmount , "invalid amount to recover tokens");
        ERC20(_tokenAddress).transfer(_to, _tokenAmount);

        emit RecoverTokens(_to, _tokenAddress, _tokenAmount);
    }

}