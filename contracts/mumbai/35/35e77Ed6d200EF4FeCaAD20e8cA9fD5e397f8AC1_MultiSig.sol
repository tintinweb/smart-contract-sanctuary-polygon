// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MultiSigFactory.sol";

contract MultiSig{
    address mainOwner;
    address[] walletOwners;
    uint transferId = 0;
    uint depositId = 0;
    uint withdrawId = 0;
    uint limit;
    string[] tokenList;
    address multiSigInstance;

    struct Transfer{
        uint id;
        string ticker;
        address sender;
        address payable receiver;
        uint amount;
        uint approvals;
        uint requestedOn;
    }

    struct Token{
        string ticker;
        address tokenAddress;
    }

    Transfer[] transferRequests;
    mapping(address => mapping(string => uint)) balances;
    mapping(address => mapping(uint => bool)) approvals;
    mapping(string => Token) tokenMapping;

    event walletOwnerAdded(address addedBy, address ownerAdded, uint transactionOn);
    event walletOwnerRemoved(address removedBy, address ownerRemoved, uint transactionOn);
    event fundDeposited(uint depositId, address sender, uint amount, uint transactionOn);
    event fundWithdraw(uint withdrawId, address sender, uint amount, uint transactionOn);
    event tokenWithdraw(uint withdrawId, address sender, string ticker, uint amount, uint transactionOn);
    event transferCreated(uint transferId,string ticker, address sender, address receiver, uint amount, uint approvals, uint transactionOn);
    event transferCancelled(uint transferId, string ticker, address sender, address receiver, uint amount, uint approvals, uint transactionOn);
    event transferApproved(uint transferId, string ticker, address sender, address receiver, uint amount, uint approvals, uint transactionOn);
    event transferExecuted(uint transferId, string ticker, address sender, address receiver, uint amount, uint approvals, uint transactionOn);
    event tokenAdded(address addedBy, string ticker, address tokenAddress, uint transactionOn);
    event tokenDeposited(uint depositId, address sender, string ticker, uint amount, uint transactionOn);

    constructor(){
        mainOwner = msg.sender;
        walletOwners.push(mainOwner);
        limit = walletOwners.length - 1;
        tokenList.push("MATIC");
    }

    modifier onlyOwners(){
        bool isOwner = false;
        for(uint i=0; i<walletOwners.length; i++){
            if(walletOwners[i] == msg.sender){
                isOwner = true;
                break;
            } 
        }
        require(isOwner, "Only wallet owner can call this function");
        _;
    }

    modifier tokenExists(string memory ticker){
        if(keccak256(bytes(ticker)) != keccak256(bytes("MATIC"))) {
            
            require(tokenMapping[ticker].tokenAddress != address(0), "Token does not exixts");
        }
        _;
    }

    function addToken(string memory _ticker, address _tokenAddress) public onlyOwners{
        require(keccak256(bytes(ERC20(_tokenAddress).symbol())) == keccak256(bytes(_ticker)), "Not a valid token");
        bool duplicateToken =false;
        for(uint i =0; i<tokenList.length; i++){
            if(keccak256(bytes(tokenList[i])) == keccak256(bytes(_ticker))){
                duplicateToken = true;
            }
            //require(keccak256(bytes(tokenList[i])) == keccak256(bytes(_ticker)), "Cannot add duplicate token");
        }
        require(duplicateToken == true, "Cannot add duplicate token");
        tokenMapping[_ticker] = Token(_ticker, _tokenAddress);
        tokenList.push(_ticker);

        emit tokenAdded(msg.sender, _ticker, _tokenAddress, block.timestamp);
    }

    function addWalletOwner(address _owner, address _walletAddress, address _address) public onlyOwners{

        for(uint i=0; i<walletOwners.length; i++){
            if(walletOwners[i] == _owner){
                revert("Cannot add duplicate owners");
            } 
        }
        walletOwners.push(_owner);
        limit = walletOwners.length - 1;
        emit walletOwnerAdded(msg.sender, _owner, block.timestamp);

        _setMultiSigContractAddress(_walletAddress);
        _callAddOwner(_owner, _address);
    }

    function removeWalletOwner(address _owner, address _walletAddress, address _address) public onlyOwners{
        bool hasBeenFound = false;
        uint ownerIndex;

        for(uint i=0; i< walletOwners.length; i++){
            if(walletOwners[i] == _owner){
                hasBeenFound = true;
                ownerIndex = i;
                break;
            }
        }
        require(hasBeenFound, "Wallet owner not found");
        walletOwners[ownerIndex] = walletOwners[walletOwners.length - 1];
        limit = walletOwners.length - 1;
        walletOwners.pop();
        emit walletOwnerRemoved(msg.sender, _owner, block.timestamp);

        _setMultiSigContractAddress(_walletAddress);
        _callRemoveOwner(_owner, _address);
    }

    function deposit(string memory _ticker, uint _amount) public payable onlyOwners tokenExists(_ticker) {
        //require(msg.value >0, "Value can't be zero");
        require(balances[msg.sender][_ticker] >=0, "cannot deposit 0");
        if(keccak256(bytes(_ticker)) == keccak256(bytes("MATIC"))){
            balances[msg.sender]["MATIC"] += msg.value;
            emit fundDeposited(depositId,msg.sender, msg.value, block.timestamp);
        }else{
            //require(tokenMapping[_ticker].tokenAddress != address(0), "Token does not exist");
            balances[msg.sender][_ticker] += _amount;
            IERC20(tokenMapping[_ticker].tokenAddress).transferFrom(msg.sender,address(this), _amount);
            emit tokenDeposited(depositId, msg.sender, _ticker, _amount, block.timestamp);
        }
        depositId++;
        
    }

    function withdraw(string memory _ticker, uint _amount) public onlyOwners tokenExists(_ticker){
        require(balances[msg.sender][_ticker] >= _amount);
        balances[msg.sender][_ticker] -= _amount;

        if(keccak256(bytes(_ticker)) == keccak256(bytes("MATIC"))){
            payable(msg.sender).transfer(_amount);
            emit fundWithdraw(withdrawId,msg.sender, _amount, block.timestamp);
        }else{
            require(tokenMapping[_ticker].tokenAddress != address(0), "Token does not exist");
            balances[msg.sender][_ticker] -= _amount;
            IERC20(tokenMapping[_ticker].tokenAddress).transfer(msg.sender, _amount);
            emit tokenWithdraw(withdrawId,msg.sender, _ticker, _amount, block.timestamp);
        }
        withdrawId++;
        
        
    }

    function createTrnasferRequest(string memory ticker, address payable receiver, uint amount) public onlyOwners tokenExists(ticker){
        
        require(balances[msg.sender][ticker] >= amount, "insufficent funds to create a transfer");
        
        for (uint i = 0; i < walletOwners.length; i++) {
            
            require(walletOwners[i] != receiver, "cannot transfer funds withiwn the wallet");
        }
        
        balances[msg.sender][ticker] -= amount;
        transferRequests.push(Transfer(transferId, ticker, msg.sender, receiver, amount, 0, block.timestamp));
        
        transferId++;
        emit transferCreated(transferId, ticker, msg.sender, receiver, amount, 0, block.timestamp);
        
    }

    function cancelTransferRequest(uint id) public onlyOwners {
        
         string memory ticker = transferRequests[id].ticker;
        bool hasBeenFound = false;
        uint transferIndex = 0;
        for (uint i = 0; i < transferRequests.length; i++) {
            
            if(transferRequests[i].id == id) {
                
                hasBeenFound = true;
                break;
               
            }
            
             transferIndex++;
        }
        
        require(transferRequests[transferIndex].sender == msg.sender, "only the transfer creator can cancel");
        require(hasBeenFound, "transfer request does not exist");
        
        balances[msg.sender][ticker] += transferRequests[transferIndex].amount;
        
        transferRequests[transferIndex] = transferRequests[transferRequests.length - 1];

            emit transferCancelled(
            transferRequests[transferIndex].id,
            'MATIC',
            msg.sender, 
            transferRequests[transferIndex].receiver, 
            transferRequests[transferIndex].amount,
            transferRequests[transferIndex].approvals,
            transferRequests[transferIndex].requestedOn
         );
        
        transferRequests.pop();
    }

    

    function approveTransfer(uint _id, string memory _ticker) public onlyOwners{
        bool hasBeenFound = false;
        uint transferIndex = 0;
        
        for(uint i=0; i<transferRequests.length; i++){
            if(transferRequests[i].id == _id){
                hasBeenFound = true;
                break;
            }
            transferIndex++;
        }

        require(hasBeenFound, "Transfer request not found");
        require(transferRequests[transferIndex].receiver == msg.sender, "cannot approve your own transfer");
        require(approvals[msg.sender][_id] == false, "cannot approve twice");

        transferRequests[transferIndex].approvals += 1;
        approvals[msg.sender][_id] = true;
        emit transferApproved(
            transferRequests[transferIndex].id,
            _ticker,
            msg.sender, 
            transferRequests[transferIndex].receiver, 
            transferRequests[transferIndex].amount,
            transferRequests[transferIndex].approvals,
            transferRequests[transferIndex].requestedOn
        );

        if(transferRequests[transferIndex].approvals == limit){
            _transferFunds(transferIndex, _ticker);
        }
    }

    function getTransferRequests() public view returns(Transfer[] memory){
        return transferRequests;
    }

    function getApprovals(uint id) public view returns(bool){
        return approvals[msg.sender][id];
    }

    function getLimit() public view returns(uint){
        return limit;
    }

    function getBalance(string memory _ticker) public view tokenExists(_ticker) returns(uint){
        return balances[msg.sender][_ticker];
    }

    function getNumberOfApprovals(uint id) public view returns(uint){
        return transferRequests[id].approvals;
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function getContractERC20Balance(string memory ticker) public view tokenExists(ticker) returns(uint) {
        
        return balances[address(this)][ticker];
    }

    function getWalletOwners() public view returns(address[] memory){
        return walletOwners;
    }

    function getAllTokens() public view returns(string[] memory){
        return tokenList;
    }

    function _transferFunds(uint id, string memory ticker) private{
        balances[transferRequests[id].receiver][ticker] += transferRequests[id].amount;

        if(keccak256(bytes(ticker)) == keccak256(bytes("MATIC"))){
            transferRequests[id].receiver.transfer(transferRequests[id].amount);
        }else{
            IERC20(tokenMapping[ticker].tokenAddress).transfer(transferRequests[id].receiver, transferRequests[id].amount);
        }
        transferRequests[id] = transferRequests[transferRequests.length - 1];
        emit transferExecuted(
            transferRequests[id].id, 
            ticker,
            msg.sender, 
            transferRequests[id].receiver, 
            transferRequests[id].amount,
            transferRequests[id].approvals,
            transferRequests[id].requestedOn
        );
        transferRequests.pop();
    }

    function _callAddOwner(address _owner, address _multisigContractInstance) private{
        MultiSigFactory factory = MultiSigFactory(multiSigInstance);
        factory.addNewWalletInstance(_owner, _multisigContractInstance);
    }

    function _callRemoveOwner(address _owner, address _multisigContractInstance) private{
        MultiSigFactory factory = MultiSigFactory(multiSigInstance);
        factory.removeWalletInstance(_owner, _multisigContractInstance);
    }

    function _setMultiSigContractAddress(address _walletAddress) private{
        multiSigInstance = _walletAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import './MultiSig.sol';

contract MultiSigFactory{

    struct UserWallet{
        address walletAddress;
    }
    UserWallet[] userWallets;
    MultiSig[] multiSigWalletInstances;

    mapping(address => UserWallet[]) ownerWallets;

    event walletCreated(address createdBy, address walletContractAddress, uint transactionOn);

    function createWallet() public {
        MultiSig newMultiSigWalletContract = new MultiSig();
        multiSigWalletInstances.push(newMultiSigWalletContract);

        UserWallet[] storage newWallet = ownerWallets[msg.sender];
        newWallet.push(UserWallet(address(newMultiSigWalletContract)));

        emit walletCreated(msg.sender, address(newMultiSigWalletContract), block.timestamp);
    }

    function addNewWalletInstance(address _owner, address _walletAddress) public{
        UserWallet[] storage newWallet = ownerWallets[_owner];
        newWallet.push(UserWallet(_walletAddress));
    }

    function removeWalletInstance(address _owner, address _walletAddress) public{
        UserWallet[] storage newWallet = ownerWallets[_owner];

        bool hasBeenFound = false;
        uint walletIndex;

        for(uint i=0; i<newWallet.length; i++){
            if(newWallet[i].walletAddress == _walletAddress){
                hasBeenFound = true;
                walletIndex =i;
                break;
            }
        }
        require(hasBeenFound, "the owners does not own the specified wallet");

        newWallet[walletIndex] = newWallet[newWallet.length - 1];
        newWallet.pop();
    }

    function getOwnerWallets(address _owner) public view returns(UserWallet[] memory){
        return ownerWallets[_owner];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}