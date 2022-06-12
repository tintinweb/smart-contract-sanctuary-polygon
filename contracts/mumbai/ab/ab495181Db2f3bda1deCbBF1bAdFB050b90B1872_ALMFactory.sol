// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ALM.sol";

contract ALMFactory is Ownable {

    address private constant MATIC = 0x0000000000000000000000000000000000001010;
    mapping(uint32 => mapping(string => address)) public almTokenMapping;
    event ALMCreated(uint32 indexed releaseId, string indexed symbol, address almAddress);
    
    /**
        Creates new ALM token
    */
    function createALM (uint32 releaseId_, address owner_, string memory name_, string memory symbol_) external onlyOwner returns(address){
        // Requires new mapping for ALM token creation
        require(almTokenMapping[releaseId_][symbol_] == address(0), 'The release id and symbol have already been created for this ALM');
        
        // Creates new ALM token
        ALM almToken = new ALM(releaseId_, owner_, name_, symbol_);

        // Sets mapping, emits ALMCreated, and transfers ownership to msg.sender
        almTokenMapping[releaseId_][symbol_] = address(almToken);
        emit ALMCreated(releaseId_, symbol_, address(almToken));
        almToken.transferOwnership(owner_);

        return address(almToken);
    }

    /**
        Function to Provide Reward to ALM
    */
    function provideReward(ALM almToken, IERC20 token, uint256 amount) payable external {
        if(address(token) == MATIC){
            require(msg.value > 0,'No funds were sent to provide reward');
            // low level function call to send matic to function
            (bool success, ) =  payable(address(almToken)).call{ value: msg.value }(abi.encodeWithSelector(ALM.initializeReward.selector, token, amount));
            require(success, "Provide reward failed.");
        }else{
            require(amount > 0,'No funds were sent to provide reward');
            require(msg.value == 0,'Do not send MATC when purchasing with ERC20');
            // Transfer tokens to this address
            SafeERC20.safeTransferFrom(token, msg.sender, address(this), amount);

            // Moves approved amount to amount provided
            SafeERC20.safeApprove(token, address(almToken), amount);

            // Initalizes reward
            almToken.initializeReward(token, amount);

            // Moves approved amount back to 0
            SafeERC20.safeApprove(token, address(almToken), 0);
        }

    }

    /**
        Function to withdraw ERC20 or MATIC
    */
    function withdrawFunds(address token) external onlyOwner {
        if(token == MATIC){
            require(address(this).balance > 0, 'ALMFactory has no funds for this token to withdraw.');
            (bool success, ) =  owner().call{ value: address(this).balance }("");
            require(success, "Withdraw failed.");
        }else{
            require(IERC20(token).balanceOf(address(this)) > 0, 'ALMFactory has no funds for this token to withdraw.');
            SafeERC20.safeTransfer(IERC20(token), owner(), IERC20(token).balanceOf(address(this)));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
    ALM base contract
*/
contract ALM is ERC20, Ownable, ReentrancyGuard {

    uint256 public rewardWindowTimestamp;
    uint256 public currentReward;
    uint256 public currentRewardRemaining;
    uint256 private currentIndex;
    address private constant MATIC = 0x0000000000000000000000000000000000001010;
    uint32 public releaseId;
    uint32 public batchAmount;
    uint8 public daysRewardWindowIsOpen;
    bool public isRewardWindowOpen;
    bool public isAirDropComplete;
    IERC20 public currentRewardToken;

    mapping (address => uint256) public totalRewardMapping;

    struct UserRewardInfo{
        uint256 totalRewardMapping;
        uint256 claimedReward;
        uint256 unclaimedReward;
    }
    mapping (address => mapping(address => UserRewardInfo)) private userClaimedRewardMapping;

    address[] public airDropUserArray;
    mapping (address => uint256) private airDropUserIndex;

    event RewardWindowOpen(address indexed rewardToken, uint256 rewardAmount);
    event RewardWindowClosed(address indexed rewardToken, uint256 rewardAmount);
    event TransferReward(address indexed from, address indexed to, uint256 claimedRewardAmount, uint256 unclaimedRewardAmount);

    // Due to Ownable openzeppelin contract the factory will have to call transfer ownership
    // after new ALM token has been created
    constructor(uint32 releaseId_, address owner_, string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        // Sets release id for ALM
        releaseId = releaseId_;
        // Mints to user 100,000 with decimal place of 18
        _mint(owner_,100000*10**18);

        // Adds owner to air drop user array
        airDropUserIndex[owner_] = 0;
        airDropUserArray.push(owner_);

        // Initializes default values
        batchAmount = 10;
        isAirDropComplete = true;
        daysRewardWindowIsOpen = 1;
    }
    
    /**
        Fallback function that reverts any value sent that didn't make it to
        the initializeReward function.
    */
    fallback() payable external   {
        require(false,'Failed to send correct value');
    }

    /**
        Initializes reward info for the current reward period
    */
    function initializeReward(IERC20 token, uint256 amount) payable external onlyWhenWindowIsNotOpen {
        // Check if funds were sent
        if(address(token) == MATIC){
            require(msg.value > 0,'No funds were sent to provide reward');
            amount = msg.value;
        }else{
            require(amount > 0,'No funds were sent to provide reward');
        }

        isRewardWindowOpen = true;
        isAirDropComplete = false;

        uint256 totalReward = totalRewardMapping[address(token)];
        totalReward += amount;
        totalRewardMapping[address(token)] = totalReward;
        currentReward = amount;
        currentRewardRemaining = amount;
        currentRewardToken = token;
        currentIndex = 0;
        
        rewardWindowTimestamp = block.timestamp + uint256(daysRewardWindowIsOpen) * 60 * 60 * 24;

        // Transfer ERC20 token
        if(address(token) != MATIC){
            SafeERC20.safeTransferFrom(token, address(msg.sender), address(this), amount);
        }
        emit RewardWindowOpen(address(token), amount);
    }

    /**
        Air drop reward iterates through air drop user array to send rewards to 
        user owned addresses. Smart contracts owning ALM tokens will not get an air
        drop. The smart contracts owning ALM tokens will have to pull rewards with
        claimReward function.
    */
    function airDropReward() external onlyWhenAirDropIsNotFinished onlyWhenWindowIsOpen nonReentrant returns(bool isComplete){
        require(currentRewardRemaining > 0, 'Current reward has been claimed');
        require(currentRewardToken.balanceOf(address(this)) > 0, 'Not enough ERC20 token available');

        uint256 tempValue = 0;
        uint256 totalReward = totalRewardMapping[address(currentRewardToken)];

        for(uint256 i = currentIndex; i < currentIndex+batchAmount; i++){

            address currentIndexAddress = airDropUserArray[i];
            
            // We skip sending rewards to smart contracts to avoid
            // rewards being lost by sending to liquidity pool smart 
            // contracts.
            if(isContract(currentIndexAddress) == true){
                continue;
            }
            // If user hasn't claimed reward or if unclaimedReward value exists for user
            if(
                userClaimedRewardMapping[currentIndexAddress][address(currentRewardToken)].totalRewardMapping < totalReward
                || userClaimedRewardMapping[currentIndexAddress][address(currentRewardToken)].unclaimedReward > 0
                ){
                    uint256 amountToTransfer = getRewardAmountToTransfer(currentIndexAddress);
                    currentRewardRemaining -= amountToTransfer;
                    if(address(currentRewardToken) == MATIC){
                        (bool success, ) =  payable(address(currentIndexAddress)).call{ value: amountToTransfer }("");
                        require(success, "Provide reward failed.");
                    }else{
                        SafeERC20.safeTransfer(currentRewardToken, currentIndexAddress, amountToTransfer);
                    }
            }

            // If we reach the end, we set variables needed to identify 
            // we have sent all air drop info
            if(i >= airDropUserArray.length-1){
                currentIndex = 0;
                isAirDropComplete = true;
                return true;
            }

            tempValue = i;
        }
        // Only alters currentIndex state variable after for loop has been completed
        currentIndex = tempValue;

        isComplete = false;
    }

    /**
        Allows for users and smart contracts to pull rewards
    */
    function claimReward() nonReentrant onlyWhenWindowIsOpen external {
        require(isRewardWindowOpen, 'Reward window is not open');
        require(currentRewardToken.balanceOf(address(this)) > 0, 'Not enough reward tokens are available');
        uint256 amountToTransfer = getRewardAmountToTransfer(msg.sender);
        currentRewardRemaining -= amountToTransfer;
        if(address(currentRewardToken) == MATIC){
            (bool success, ) =  payable(address(msg.sender)).call{ value: amountToTransfer }("");
            require(success, "Provide reward failed.");
        }else{
            SafeERC20.safeTransfer(currentRewardToken, msg.sender, amountToTransfer);
        }
    }

    /**
        Function that gets user reward amount.
    */
    function viewUserRewardAmount(address user) public view returns(uint256 amountOwed){
        uint256 unclaimedRewardAmount;
        if(isRewardWindowOpen == false){
            return 0;
        }
        // Give entire reward if hasn't been claimed
        if(userClaimedRewardMapping[user][address(currentRewardToken)].totalRewardMapping < totalRewardMapping[address(currentRewardToken)]){
            unclaimedRewardAmount = balanceOf(user);
        }else{
            // Claim unclaimedRewards on user struct if already claimed
            unclaimedRewardAmount = userClaimedRewardMapping[user][address(currentRewardToken)].unclaimedReward;
            
        }
        amountOwed = unclaimedRewardAmount*currentReward/totalSupply();
    }

    /**
        Withrdraws funds and closes reward window
    */
    function withdrawFundsAndCloseRewardWindow(address token) external onlyOwner onlyWhenPassedWindow {
        if(isRewardWindowOpen){
            closeRewardWindow();
        }
        if(token == MATIC){
            if(address(this).balance > 0){
                (bool success, ) =  owner().call{ value: address(this).balance }("");
                require(success, "Withdraw failed.");
            }
        }else{
            if(IERC20(token).balanceOf(address(this)) > 0){
                if(address(currentRewardToken) == MATIC){
                    (bool success, ) =  payable(address(owner())).call{ value: address(this).balance }("");
                    require(success, "Provide reward failed.");
                }else{
                    SafeERC20.safeTransfer(IERC20(token), owner(), IERC20(token).balanceOf(address(this)));
                }
            }
        }
    }

    /**
        Closed reward window
    */
    function closeRewardWindow() private {
        isRewardWindowOpen = false;
        currentRewardRemaining = 0;
        currentReward = 0;
        if(isAirDropComplete == false){
            isAirDropComplete = true;
        }
        emit RewardWindowClosed(address(currentRewardToken), currentReward);
    }

    /**
        Returns air drop user array length
    */
    function airDropUserArrayLength() external view returns(uint256){
        return airDropUserArray.length;
    }

    /**
        Returns boolean to determine if address is a smart contract
    */
    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    /**
        Override function to allow for transferReward to be called
    */
    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();

        pushToAirDropArray(to);
        transferReward(owner, to, amount);

        _transfer(owner, to, amount);

        removeFromAirDropArray(owner);

        return true;
    }

    /**
        Override function to allow for transferReward to be called
    */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();

        pushToAirDropArray(to);
        transferReward(from, to, amount);

        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);

        removeFromAirDropArray(from);

        return true;
    }

    /**
        Function called when transfer or transferFrom is called
    */
    function transferReward(address from, address to, uint256 amount) private onlyWhenWindowIsOpen {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");

        initializeUserRewardInfo(from);
        initializeUserRewardInfo(to);
        // Start out with unclaimed reward amount
        uint256 unclaimedRewardAmount = userClaimedRewardMapping[from][address(currentRewardToken)].unclaimedReward;
        uint256 claimedRewardAmount = 0;

        // if amount is greater than unclaimed reward, we move unclaimed reward over and then
        // move claimed over for claimed based on amount-unclaimedRewardAmount delta
        if(amount > unclaimedRewardAmount){
            userClaimedRewardMapping[to][address(currentRewardToken)].unclaimedReward += unclaimedRewardAmount;
            userClaimedRewardMapping[from][address(currentRewardToken)].unclaimedReward -= unclaimedRewardAmount;

            claimedRewardAmount = amount-unclaimedRewardAmount;
            userClaimedRewardMapping[to][address(currentRewardToken)].claimedReward += claimedRewardAmount;
            userClaimedRewardMapping[from][address(currentRewardToken)].claimedReward -= claimedRewardAmount;

        }else{// else amount is <= unclaimed amount, so we can just move the amount over to unclaimed
            userClaimedRewardMapping[to][address(currentRewardToken)].unclaimedReward += amount;
            userClaimedRewardMapping[from][address(currentRewardToken)].unclaimedReward -= amount;
        }

        emit TransferReward(from, to, claimedRewardAmount, unclaimedRewardAmount);
    }

    /**
        Function to initialize userClaimedRewardMapping if transfering ALM tokens
    */
    function initializeUserRewardInfo(address user) private {
        if(userClaimedRewardMapping[user][address(currentRewardToken)].totalRewardMapping < totalRewardMapping[address(currentRewardToken)]){
            userClaimedRewardMapping[user][address(currentRewardToken)] = UserRewardInfo(totalRewardMapping[address(currentRewardToken)], 0, balanceOf(user));
        }
    }

    /**
        Function find amount to transfer
    */
    function getRewardAmountToTransfer(address user) private returns(uint256 amountToTransfer){
        amountToTransfer = viewUserRewardAmount(user);
        userClaimedRewardMapping[user][address(currentRewardToken)] = UserRewardInfo(totalRewardMapping[address(currentRewardToken)], balanceOf(user),0);
    }

    /**
        Function to add users to air drop array
    */
    function pushToAirDropArray(address user) private {
        if(airDropUserIndex[user] == 0 && airDropUserArray[0] != user){
            airDropUserIndex[user] = airDropUserArray.length;
            airDropUserArray.push(user);
        }
    }

    /**
        Function to remove users from air drop array when necessary
    */
    function removeFromAirDropArray(address from) private {
        if(balanceOf(from) == 0){
            uint256 pos = airDropUserIndex[from];
            delete airDropUserIndex[from];

            address tempAddr = airDropUserArray[airDropUserArray.length-1];
            airDropUserArray[pos] = tempAddr;
            airDropUserArray.pop();

        }
    }

    /**
        Function to adjust reward window
    */
    function setDaysRewardWindowIsOpen(uint8 days_) external onlyOwner {
        daysRewardWindowIsOpen = days_;
    }

    /**
        Modifier for is reward open == false
    */
    modifier onlyWhenWindowIsNotOpen() {
        require(isRewardWindowOpen == false, 'Reward window is currently active. Please wait for this reward to finish before initializing another reward window.');
        _;
    }

    /**
        Modifier for is reward open == true
    */
    modifier onlyWhenWindowIsOpen() {
        if (isRewardWindowOpen == true) {
            _;
        }
    }

    /**
        Modifier for is air drop complete == false
    */
    modifier onlyWhenAirDropIsNotFinished() {
        require(isAirDropComplete == false, 'Air drop has already been completed for this reward window. Please use claimReward to retreive unclaimed tokens.');
        _;
    }

    /**
        Modifier for is block timestamp >= reward timestamp
    */
    modifier onlyWhenPassedWindow() {
        require(block.timestamp >= rewardWindowTimestamp, 'Reward window is still within date range.');
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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