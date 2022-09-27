/**
 *Submitted for verification at polygonscan.com on 2022-09-27
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-28
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/Swapz.sol



pragma solidity 0.8.8;


// This contract is owned by Decentralized Swapz Network
// Decentralized Swapz Network is Mesh network based on Threshold Signature Scheme with 2/3 PoS Consensus. 

abstract contract TokenFactory {
    function create(uint contractType , string memory name, string memory symbol) virtual public returns(address);
} 

abstract contract Token is IERC20 {
    function mint(address _address, uint256 _amount) virtual public;
    function burn(address _address, uint256 _amount) virtual public;
    function setBaseURI(string memory _baseUri) virtual public;
    function transferOwnership(address newAddress) virtual public;
    function tokenType() public virtual returns (uint);
}

abstract contract FlashReceiver {
    function executeOperation(address token, uint amount, uint fee, bytes calldata params) virtual public;
}

// Crosschain Liquidity Pool
contract SwapzMultichainBridge {
    
    TokenFactory public tokenFactory;

    function changeTokenFactory(address newTokenFactory) public onlyAdmin {
        tokenFactory = TokenFactory(newTokenFactory);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "OWNER");
        _;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender || owner == msg.sender, "ADMIN");
        _;
    }

    address public owner;
    address public admin;

    function transferOwnership(address _address) virtual public onlyOwner() {
        owner = _address;
    }

    function transferAdmin(address _address) virtual public onlyAdmin() {
        owner = _address;
    }
    
    // Define the token 
    constructor() {
        tokenToAllowed[address(0x0)] = true;
        tokenFactory = TokenFactory(0x46f62e61160f89Fb9423C62EC4A43A12AC3aAa2B);
        owner = 0xdF2DAc8147b38bB4BBAf4a626E271a153bBC359F; 
        admin = 0xdF2DAc8147b38bB4BBAf4a626E271a153bBC359F;
    }    
    
    uint public airdrop = 1 ether;

    mapping(bytes => address) public assetToAddress;
    mapping(address => bytes) public addressToAsset;
    mapping(address => bool) public tokenToAllowed;
    mapping(bytes => uint256) public chainFee;
    mapping(bytes => bool) public knownForainTxs;
    
    function setBaseURI(address token, string memory uri) public onlyAdmin {
        Token(token).setBaseURI(uri);
    }

    function allowSwapToken(address _token, bool _allow) onlyAdmin public {
        tokenToAllowed[_token] = _allow;
    }
    
    function changeChainFee(bytes calldata _chainId, uint _chainFee) public onlyAdmin {
        chainFee[_chainId] = _chainFee;
    }

    function changeTokenOwner(address _token, address _newOwner) public onlyAdmin {
        Token t = Token(_token);
        t.transferOwnership(_newOwner);
    }

    function assignTokenToAsset(bytes memory _assetId, address _token) public onlyAdmin {
        assetToAddress[_assetId] = _token;
        addressToAsset[_token] = _assetId;

    }


    function chainAirdrop(uint _airdrop) public onlyAdmin {
        airdrop = _airdrop;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        } 
    }


    function sendAll(address[] calldata keepers, bytes[] calldata tokens, uint[] calldata amounts, bytes[] calldata foreignTx) external onlyOwner {
        
        for (uint i = 0; i < keepers.length; i++) {

            require(knownForainTxs[foreignTx[i]] == false, "KNOWN");
            knownForainTxs[foreignTx[i]] = true;

            send(keepers[i], tokens[i], amounts[i]);
            
        }

    }
    
    function send(address keeper, bytes calldata token, uint amount) private {

        if (token.length == 20) {
            sendNative(keeper, bytesToAddress(token), amount);
        }
        else {
            sendWrapped(keeper, token, amount);
        }

    }

    
    function sendWrapped(address keeper, bytes calldata asset, uint256 amount) private {

            if (assetToAddress[asset] == address(0x0)) {
                
                address token_address = tokenFactory.create(getType(asset), getName(asset), getSymbol(asset));
                
                assetToAddress[asset] = token_address;
                addressToAsset[token_address] = asset;
                allowSwapToken(token_address, true);

                
                changeChainFee(getChainId(asset), 1 ether);
            }
            
            Token t2 = Token(assetToAddress[asset]);
            t2.mint(keeper, amount); 
    
    }
    
    uint public gasLimit = 21000;

    function chainGasLimit(uint _gasLimit) public onlyAdmin {
        gasLimit = _gasLimit;
    }

    function transfer(address _to , uint256 value) private {
        _to.call{ value: value, gas: gasLimit }('');
        //payable(_to).transfer(value);
    }

    function sendNative(address keeper, address token, uint amount) private {
            
        if (token == address(0x0)) {
            
            transfer(keeper, amount);
            //payable(keeper).transfer(amount);

        } else {
            // the transaction should reverted if not enough balance (each ERC20 should be audited)
            Token(token).transfer(keeper, amount);

            if (address(this).balance > airdrop) {
                transfer(keeper, airdrop);
                //payable(keeper).transfer(airdrop);
            }
        }

    }

    function flashLoan(uint _amount, address _token, FlashReceiver _receiver, bytes calldata _params) public {

        uint _fee = _amount / 10000;
        bool isNative = _token == address(0x0);
        Token token = Token(_token);
        address receiver = address(_receiver);
        address sender = address(this);

        uint256 balanceBefore = isNative ? sender.balance : token.balanceOf(sender);
        require(token.tokenType() == 0, "ERC20");
        require(_amount <= balanceBefore, "BALANCE");

        if (isNative) {
            //payable(receiver).transfer(_amount);
            transfer(receiver, _amount);
        }
        else {
            token.transfer(receiver, _amount);
        }

        _receiver.executeOperation(_token, _amount, _fee, _params);

        uint256 balanceAfter  = isNative ? sender.balance : token.balanceOf(sender);

        require(balanceBefore + _fee == balanceAfter, "RESULT");

    }

    mapping(address => bool) referrals;

    function setAcceptedReferral(address referral, bool accepted) public onlyAdmin {
        referrals[referral] = accepted;
    }

    

    function swapRequestNative(uint _amount, address _token, bytes calldata chainId, address referral) external payable {
        
        uint256 fee = chainFee[chainId];

        require(tokenToAllowed[_token], "DISABLED");
        
        require(fee > 0, "FEE");
        
        if (_token == address(0x0)) {
            require(msg.value == fee + _amount, "AMOUNT");
        }
        else {
            require(msg.value == fee, "FEE");
            // the transaction should reverted if not enough balance (each ERC20 should be audited)
            
            Token(_token).transferFrom(msg.sender, address(this), _amount);
        }
        if (referrals[referral]) {
            uint fee2 = fee / 2;
            //payable(owner).transfer(fee - fee2);
            transfer(owner, fee - fee2);
            //payable(referral).transfer(fee2);
            transfer(referral, fee2);
            
        }
        else {
            //payable(owner).transfer(fee);
            transfer(owner, fee);
        }
        

        emit CrossSwap(_amount, msg.sender, chainId, _token);
    }

    // Mash nodes connected to this event
    event CrossSwap ( uint256 value, address recipient, bytes chainIdOrAssetId, address token );
    
    function getName(bytes calldata assetId) public pure returns (string memory) {
        //return "";
        bytes memory s = assetId[15:35];
        return string(s);
    } 

    function getSymbol(bytes calldata assetId) public pure returns (string memory) {
        //return "";
        bytes memory s = assetId[5:15];
        return string(s);
    } 

    function getType(bytes calldata asset) public pure returns (uint8) {
        return uint8(bytes1(asset[4:6]));
    }

    function getChainId(bytes calldata assetId) public pure returns (bytes calldata) {
        return assetId[0:4];
    } 

    function swapRequestWrapped(address _token, uint _amount, address referral) external payable {                
        bytes memory chainId = this.getChainId(addressToAsset[_token]);

        uint256 fee = chainFee[chainId];

        require(fee > 0, "CHAIN");

        require(msg.value == chainFee[chainId], "FEE");
        
        Token(_token).burn(msg.sender, _amount);

        if (referrals[referral]) {
            uint fee2 = fee / 2;
            transfer(owner, fee - fee2);
            transfer(referral, fee2);
            
            
        }
        else {
            //payable(owner).transfer(fee);
            transfer(owner, fee);
        }

        emit CrossSwap(_amount, msg.sender, addressToAsset[_token], _token);
    }
    
    // Added to make deposits
    receive() external payable {} 

}