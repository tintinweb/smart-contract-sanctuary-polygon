// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
contract PLOVE is ERC20, Ownable{
    using SafeMath for uint256;
    // keeping it for checking, whether deposit being called by valid address or not
    address public childChainManagerProxy;
    address deployer;
    bytes32 DOMAIN_SEPARATOR;
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 constant WithdrawRequest_TYPEHASH = keccak256(
        "WithdrawRequest(uint256 Nonce)"
    );
    mapping(address => bool) public isApprovedAddress;
    mapping(address => uint256) public nonces;    //maps nonces

    constructor (
        string memory _name,
        string memory _symbol,
        address _childChainManagerProxy
    )ERC20(_name,_symbol){ 
        childChainManagerProxy = _childChainManagerProxy;
        deployer = _msgSender();

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes("MetaWithdraw")),   //name:
            keccak256(bytes('1')),          //version:
            4,                              //chainId:
            address(this)                            //verifyingContract:
        ));
    }
    modifier onlyApprovedAddresses{
        require(isApprovedAddress[_msgSender()], "You are not authorized!");
        _;
    }
    function setDOMAIN_SEPARATOR(string memory _name, string memory _version, uint256 _chainId) public onlyOwner{
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(_name)),   //name:
            keccak256(bytes(_version)),          //version:
            _chainId,                              //chainId:
            address(this)                            //verifyingContract:
        ));
    }
    // being proxified smart contract, most probably childChainManagerProxy contract's address
    // is not going to change ever, but still, lets keep it 
    function updateChildChainManager(address newChildChainManagerProxy) external {
        require(newChildChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        require(_msgSender() == deployer, "You're not allowed");

        childChainManagerProxy = newChildChainManagerProxy;
    }
    function deposit(address user, bytes calldata depositData) external {
        require(_msgSender() == childChainManagerProxy, "You're not allowed to deposit");

        uint256 amount = abi.decode(depositData, (uint256));

        _mint(user, amount);
    }
    function withdraw(address _to, uint256 _amount) external {
        if(msg.sender != _to){
            require(isApprovedAddress[_to], "NOT AUTHORIZED");
            _burn(_to, _amount);
        }
        else{
            _burn(msg.sender, _amount);    
        }
    }
    function burn(address _to, uint256 _amount) external onlyApprovedAddresses{
        _burn(_to, _amount);
    }
    function metaWithdraw(address _to, uint256 _amount, uint256 _nonce, uint8 _v, 
    bytes32 _r, bytes32 _s, address _sender) external onlyApprovedAddresses{
        require(verify(_nonce, _v, _r, _s, _sender),"INVALID-SIGNATURE");
        _burn(_to, _amount);
        nonces[_sender] ++;
    }
    function setApprovedAddresses(address _approvedAddress, bool _set) external onlyOwner(){
        isApprovedAddress[_approvedAddress] = _set;
    }
    function verify(uint256 _nonce,uint8 _v, bytes32 _r, bytes32 _s, address _sender) public view returns (bool) {
        require(_sender != address(0), "INVALID-ADDRESS");
        require(_nonce == nonces[_sender], "INVALID-NONCE");
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                WithdrawRequest_TYPEHASH,
                _nonce
            ))
        ));
        return ecrecover(digest, _v, _r, _s) == _sender;
    }
}