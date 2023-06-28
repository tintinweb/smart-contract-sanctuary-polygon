/**
 *Submitted for verification at polygonscan.com on 2023-06-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IERC20 {

    function decimals() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
    
}

library Address {
   
    function isContract(address account) internal view returns (bool) {
        
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
   
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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

}

library Strings {

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;

            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

abstract contract EIP712 {

    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

abstract contract SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
       
        bytes memory returndata = address(token).functionCall(data, "SafeTRC20: low-level call failed");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeTRC20: TRC20 operation did not succeed");
        }
    }
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


contract PokerGame is Ownable, Pausable, SafeERC20, EIP712 {

    
    address public Admin;
    address public Signer;
    address public CCC_token;

    string constant public Name = "POKER_GAME";
    string constant public Version = "1.0";
    bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address user,address requestToken,uint256 tokenAmount,uint256 nonce,uint256 deadline)");


    struct Sig{
        uint8 V;
        bytes32 R;
        bytes32 S;
    }

    mapping(uint8 => uint16 ) private plansReward;
    mapping(address => uint64) public nonce;
    
    event DepositTokens(address User, uint TokenAmount, uint DepositTime);
    event WithdrawTokens(address User, uint TokenAmount, uint WithdrawTime);
    event ClaimRewards(address User, address ClaimToken, uint ClaimAmount, uint AdminFee, uint ClaimTime);

    constructor(address _signer, 
        address _admin, 
        address _cccToken
    ) EIP712(Name, Version) {

        Signer = _signer;
        Admin = _admin;
        CCC_token = _cccToken;

        plansReward[1] = 100;
        plansReward[2] = 50;
        plansReward[3] = 100;

    }


    function pause() external onlyOwner {
        _pause();
    }

    function unPaused() external onlyOwner{
        _unpause();
    }


    function deposit(address _token,
        uint _amount
    ) external whenNotPaused {
        depositTokens(_token, _amount);
        emit DepositTokens(_msgSender(), _amount, block.timestamp);
    }

    function withdraw(
        uint _requestAmount,
        uint _deadline, 
        Sig memory _sig
    ) external whenNotPaused {

        require(_deadline >= block.timestamp && _deadline < (block.timestamp + 100), "Invalid deadline" );
        validateSignature(_msgSender(), _deadline, _requestAmount, _sig);
        nonce[_msgSender()]++;
        deliverTokens(CCC_token, _msgSender(), _requestAmount);

        emit WithdrawTokens(_msgSender(), _requestAmount, block.timestamp);
    }

    function claimRewards(
        uint8 _plan, 
        uint _rewardAmount,
        uint _deadline,
        Sig memory _sig) 
    external whenNotPaused {

        require(_plan > 0 && _plan < 4, "choose correct plan");
        require(_deadline >= block.timestamp && _deadline < (block.timestamp + 100), "Invalid deadline" );
        validateSignature(_msgSender(), _deadline, _rewardAmount, _sig);
        
        uint adminFee;

        if(_plan == 1) {
            adminFee = _rewardAmount * plansReward[_plan] / 1e4;
            _rewardAmount = _rewardAmount - adminFee;
        }else {
            adminFee = _rewardAmount - (plansReward[_plan] * (1e18));
            _rewardAmount = _rewardAmount - adminFee;
        }

        deliverTokens(CCC_token, _msgSender(), _rewardAmount);
        deliverTokens(CCC_token, Admin, adminFee);
        nonce[_msgSender()]++;

        emit ClaimRewards(_msgSender(), CCC_token, _rewardAmount, adminFee, block.timestamp);
        
    }



    function validateSignature(
        address _user,
        uint _deadline,
        uint _rewardAmount,
        Sig memory _sig
    ) internal view {
        bytes32 hash = keccak256(abi.encode(PERMIT_TYPEHASH, _user, CCC_token, _rewardAmount, nonce[_msgSender()], _deadline));
        hash = _hashTypedDataV4(hash);
        require(Signer == ECDSA.recover(hash, _sig.V, _sig.R, _sig.S), "Incorect signature");
    }


    function depositTokens(
        address _sellingToken, 
        uint _sellingAmount) 
    internal {
        safeTransferFrom(IERC20(_sellingToken), _msgSender(), address(this), _sellingAmount);
    }



    function deliverTokens(
        address _buyToken, 
        address _receiver,
        uint _buyAmount) 
    internal {
        safeTransfer(IERC20(_buyToken), _receiver, _buyAmount);
    }


    function setPlans(
        uint8 _plan, 
        uint16 planReward ) 
    external onlyOwner {
        require(_plan > 0 && _plan < 4, "choose correct plan");
        plansReward[_plan] = planReward;
    }


    function viewPlanReward(uint8 _plan) external view returns(uint reward){
        require(_plan > 0 && _plan < 4, "choose correct plan");
        return plansReward[_plan];
    }


    function setAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0x0),"Invalid admin address");
        Admin = _newAdmin;
    }

    function setCCCToken(address _newCCC) external onlyOwner {
        require(_newCCC == address(0x0),"Invalid token address");
        CCC_token = _newCCC;
    }

    function recoverTokens(
        address _recoverToken, 
        address _receiver, 
        uint _recoverAmount) 
    external onlyOwner {
        if(_recoverToken == address(0x0)){
            require(payable(_receiver).send(_recoverAmount),"Invalid BNB amount");
        }else{
            deliverTokens(_recoverToken, _receiver,_recoverAmount);
        }
    }

    

}