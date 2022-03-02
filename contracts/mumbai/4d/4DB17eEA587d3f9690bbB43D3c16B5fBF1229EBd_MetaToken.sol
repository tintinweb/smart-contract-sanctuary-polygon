/**
 *Submitted for verification at polygonscan.com on 2022-03-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "subtraction overflow");
        return a - b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
}
abstract contract Nonces {
    mapping(address => uint256) internal _nonces;
    function nonces(address owner) external view returns (uint256) {
        return _nonces[owner];
    }
}

contract MetaToken {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals;

    address public owner;
    address public currentContextAddress;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory names, string memory symbols, uint256 totalSupplys) {
        name = names;
        symbol = symbols;
        totalSupply = totalSupplys * (10 ** 6);
        decimals = 6;
        balances[msg.sender] = totalSupplys * (10 ** 6);
        owner = msg.sender;
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool){
        _transfer(_getCurrentContextAddress(), recipient, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function _transfer(address sender,address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount,"ERC20: transfer amount exceeds balance");

        balances[sender] = balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        balances[recipient] = balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function _getCurrentContextAddress() internal view returns (address) {
        address currentContextAddress_ = currentContextAddress;
        address contextAddress = currentContextAddress_ == address(0) ? msg.sender : currentContextAddress_;
        return contextAddress;
    }

    function _setCurrentContextAddressIfRequired(address signerAddress, address contextAddress) internal {
        if (signerAddress != msg.sender) {
            currentContextAddress = contextAddress;
        }
    }

}

contract Validation is Nonces {

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes public abiEncodeDomain;
    uint256 constant chainId = 9999;
    bytes32 constant salt = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558;

    struct Transaction {
        address payable to;
        uint256 amount;
        uint256 nonce;
    }

    // function getChainID() private view returns (uint256) {
    //     uint256 id;
    //     assembly {
    //         id := chainid()
    //     }
    //     return id;
    // }

    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;
    // keccak256("Transaction(address to,uint256 amount,uint256 nonce)");
    bytes32 private constant TRANSACTION_TYPEHASH = 0x67121f3f5af9e0be370d71fed1829be5ab4792b1944ba5b83393cc61d57e4b0f;


    constructor() {
        abiEncodeDomain = abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256("RasyidKaromi"), keccak256("1.0.0"), block.chainid, address(this), salt);

        DOMAIN_SEPARATOR = keccak256(
        abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256("RasyidKaromi"), keccak256("1.0.0"), block.chainid, address(this), salt));
    }

    function hashTransaction(Transaction calldata transaction) private view returns (bytes32){
        return keccak256(
                abi.encodePacked(bytes1(0x19),bytes1(0x01), DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            TRANSACTION_TYPEHASH,
                            transaction.to,
                            transaction.amount,
                            transaction.nonce
                        )
                    )
                )
            );
    }

    function isValidTransaction(address signer, Transaction calldata transaction,uint8 v,bytes32 r, bytes32 s) public view returns (bool) {
        return ecrecover(hashTransaction(transaction), v, r, s) == signer;
    }
}

contract MetaTransaction is Validation, MetaToken {

    constructor(string memory names, string memory symbols, uint256 totalSupplys) 
    MetaToken(names, symbols, totalSupplys){}

// require(block.timestamp < transaction.expirationTimeSeconds, "META_TX: Meta transaction is expired");
// require(!transactionsExecuted[transactionHash], "META_TX: Transaction already executed");
// require(tx.gasprice == requiredGasPrice, "META_TX: Gas price not matching required gas price");

    function metaTransfer(address signer, Transaction calldata transaction, uint8 v,bytes32 r,bytes32 s) public payable  returns (bool, bytes memory) {
        require(isValidTransaction(signer, transaction, v, r, s) == true, "ERROR: Invalid transaction");
        _nonces[signer]++;
        _setCurrentContextAddressIfRequired(signer, signer);
        (bool success, bytes memory data) = address(this).delegatecall(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                transaction.to,
                transaction.amount
            )
        );
        _setCurrentContextAddressIfRequired(signer, address(0));
        return (success, data);
    }

}