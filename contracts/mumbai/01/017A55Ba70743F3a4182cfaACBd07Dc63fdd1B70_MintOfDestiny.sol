/**
 *Submitted for verification at polygonscan.com on 2022-05-16
*/

// File: contracts/interfaces/IMoD.sol


pragma solidity ^0.8.0;

interface IMoD {

    // Mints a new token
    function modMint(address sendTo, uint256 tokenID) external;

    // Lookup owner of a token
    function ownerOf(uint256 tokenId) external returns(address);

    // Open Safe Transfer of tokens
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    // Allow admin to burn tokens as necessary
    function modBurn(uint256 tokenID) external;
}
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/MintOfDestiny.sol

/*

       ▄▄▄▄███▄▄▄▄    ▄█  ███▄▄▄▄       ███           ▄██████▄     ▄████████      ████████▄     ▄████████    ▄████████     ███      ▄█  ███▄▄▄▄   ▄██   ▄
     ▄██▀▀▀███▀▀▀██▄ ███  ███▀▀▀██▄ ▀█████████▄      ███    ███   ███    ███      ███   ▀███   ███    ███   ███    ███ ▀█████████▄ ███  ███▀▀▀██▄ ███   ██▄
     ███   ███   ███ ███▌ ███   ███    ▀███▀▀██      ███    ███   ███    █▀       ███    ███   ███    █▀    ███    █▀     ▀███▀▀██ ███▌ ███   ███ ███▄▄▄███
     ███   ███   ███ ███▌ ███   ███     ███   ▀      ███    ███  ▄███▄▄▄          ███    ███  ▄███▄▄▄       ███            ███   ▀ ███▌ ███   ███ ▀▀▀▀▀▀███
     ███   ███   ███ ███▌ ███   ███     ███          ███    ███ ▀▀███▀▀▀          ███    ███ ▀▀███▀▀▀     ▀███████████     ███     ███▌ ███   ███ ▄██   ███
     ███   ███   ███ ███  ███   ███     ███          ███    ███   ███             ███    ███   ███    █▄           ███     ███     ███  ███   ███ ███   ███
     ███   ███   ███ ███  ███   ███     ███          ███    ███   ███             ███   ▄███   ███    ███    ▄█    ███     ███     ███  ███   ███ ███   ███
      ▀█   ███   █▀  █▀    ▀█   █▀     ▄████▀         ▀██████▀    ███             ████████▀    ██████████  ▄████████▀     ▄████▀   █▀    ▀█   █▀   ▀█████▀


                v1.4
                @author NFTArca.de
                @title Mint of Destiny

*/


//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;







contract MintOfDestiny is Pausable, ReentrancyGuard, IERC721Receiver {

    /*

    EVENTS

    */


    // Contract address for MoD Token Minting
    IMoD private mod;

    struct role {
        uint256 totalTokensToMint;
        uint256 totalTokensAwarded;
        uint256 tokenStartID;
        uint256 tokenEndID;
        bool allowPublicMint;
        uint256 price;
        uint256 priceWETH;
        uint256 priceERC20;
        string roleToHaveToMint;
        bool hasAttachedMint;
        string attachedMintRole;
    }

    // Admins
    mapping (address => bool) admins;

    struct roleCheck {
        // Store to control minting 1 per address
        mapping (address => bool) hasRoleAwarded;

        // Store to keep track of roles based on ownership
        mapping (address => bool) hasRole;
    }

    // Keep track of each token minted and what role it belongs to
    mapping (uint256 => string) tokensAwardedToRoleMap;

    // All role details
    mapping (string => role) roles;
    mapping (string => roleCheck) roleChecks;

    // Array of role names in array for listing and mapping for quick compare
    string[] private roleNames;
    mapping (string => bool) roleNamesMap;

    // Array of tokens vaulted in the contract for the MINT OF DESTINY owner to claim
    uint256[] private modVault;

    // ERC20 Receiver for NFT purchases via ERC20
    IERC20 public paymentToken;

    // ERC20 Receiver for NFT purchases via WETH
    IERC20 public paymentTokenWETH;

    // The address to receive all funds
    address public gameWallet;


    constructor(IERC20 _paymentToken){
        paymentTokenWETH = IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
        paymentToken = IERC20(_paymentToken);
        gameWallet = msg.sender;

        // Setup the default Admin
        admins[msg.sender] = true;
    }



    /*

    MODIFIERS

    */

    modifier onlyHumans() {
        // Only puny hoomans can call this (stops scammers from phishing MOD owner)
        require(tx.origin == msg.sender, "Nope");
        _;
    }

    modifier onlyAdmins() {
        require(admins[msg.sender], "Only admins can call this function.");
        _;
    }

    modifier requireContractsSet() {
        require(address(mod) != address(0), "Contracts not set");
        _;
    }



    /*

    ADMIN FUNCTIONS

    */


    function addAdmin(address newAdmin) public onlyAdmins onlyHumans{
        admins[newAdmin] = true;
    }

    function removeAdmin(address oldAdmin) public onlyAdmins onlyHumans{
        admins[oldAdmin] = false;
    }

    function pause() public onlyAdmins onlyHumans {
        _pause();
    }

    function unpause() public onlyAdmins onlyHumans {
        _unpause();
    }

    function privateMint(address sendTo, string calldata roleName) public onlyAdmins onlyHumans whenNotPaused {
        // Call to mint
        mint(sendTo, roleName, false);
    }

    function addRole(string memory roleName, uint256 tokenLimit, bool allowPublicMint, uint256 price, uint256 priceERC20, uint256 priceWETH, string memory mandatoryRole, bool hasAttachedMint, string memory attachedMintRole) public onlyAdmins onlyHumans whenNotPaused {

        // Verify that the role exits
        require(!roleNamesMap[roleName], "That role already exists");

        // Prevent attached roles from being self for infinite minting loop
        require(!stringsEqual(roleName, attachedMintRole), "Attached Minting roles cannot be of the defining role.");

        // Make sure there's a valid token limit
        require(tokenLimit > 0, "You need more than a 0 token limit");

        // If there is a mandatory role, make sure it exists first
        if (!stringsEqual(mandatoryRole, "")){
            require(roleNamesMap[mandatoryRole], "Mandatory role doesn't exist. Make that one first");
        }

        // If there is an attached mint role, make sure it exists first
        if (hasAttachedMint){
            require(roleNamesMap[attachedMintRole], "Attached mint role doesn't exist. Make that one first");
        }

        // The first role must be MINT OF DESTINY
        if (roleNames.length == 0){
            roleName = "MINT OF DESTINY";
            tokenLimit = 1;
            allowPublicMint = false;
            price = 0;
            priceERC20 = 0;
            priceWETH = 0;
        }

        // The second role must be Kill Screen
        if (roleNames.length == 1){
            roleName = "Kill Screen";
            tokenLimit = 20;
            allowPublicMint = false;
            price = 0;
            priceERC20 = 0;
            priceWETH = 0;
        }

        // Get the token start ID by grabbing the end ID of that last role
        uint256 lastEndID = 0;
        if (roleNames.length > 0){
            lastEndID = roles[roleNames[(roleNames.length - 1)]].tokenEndID;
        }

        // add the role to the array
        roleNames.push(roleName);

        // Add the role to the role map
        roleNamesMap[roleName] = true;

        // add the role to the mapping
        role memory newRole;
        newRole.totalTokensToMint = tokenLimit;
        newRole.totalTokensAwarded = 0;
        newRole.allowPublicMint = allowPublicMint;
        newRole.tokenStartID = lastEndID + 1;
        newRole.tokenEndID = newRole.tokenStartID + tokenLimit - 1;
        newRole.price = price;
        newRole.priceERC20 = priceERC20;
        newRole.priceWETH = priceWETH;
        newRole.roleToHaveToMint = mandatoryRole;
        newRole.hasAttachedMint = hasAttachedMint;
        newRole.attachedMintRole = attachedMintRole;

        roles[roleName] = newRole;

        // The first 2 roles are the MINT OF DESTINY and Kill Screen tokens, so we skip them
        if (roleNames.length > 2){
            // Mint the first one and stake it to the contract for MINT OF DESTINY Owner to claim
            mint(address(this), roleName, true);
        }
    }

    function updateRoleDetails(string memory roleName, bool allowPublicMint, uint256 price, uint256 priceERC20, uint256 priceWETH, string calldata mandatoryRole, bool hasAttachedMint, string calldata attachedMintRole) public onlyAdmins {

        // Verify that the role exits
        require(roleNamesMap[roleName], "That role does not exists.");

        // Prevent attached roles from being self for infinite minting loop
        require(!stringsEqual(roleName, attachedMintRole), "Attached Minting roles cannot be of the defining role.");

        roles[roleName].allowPublicMint = allowPublicMint;
        roles[roleName].price = price;
        roles[roleName].priceERC20 = priceERC20;
        roles[roleName].priceWETH = priceWETH;
        roles[roleName].roleToHaveToMint = mandatoryRole;
        roles[roleName].hasAttachedMint = hasAttachedMint;
        roles[roleName].attachedMintRole = attachedMintRole;
    }

    function killRole(string memory roleName) public onlyAdmins onlyHumans {

        // Verify that the role exits
        require(roleNamesMap[roleName], "That role does not exists.");

        // Make sure that it's the last role added
        require(stringsEqual(roleNames[roleNames.length - 1], roleName), "You can only modify the token limits of the last role added");

        // Make sure that we haven't minted any of these (except the one for the vault)
        require(roles[roleName].totalTokensAwarded < 2, "Too late, tokens have already been minted for this role");

        delete roles[roleName];
        delete roleNamesMap[roleName];
        roleNames.pop();

    }

    function updateRoleOwnership(uint256 tokenId, address addr, bool flag) external onlyAdmins {

        // Get the role from the token
        string memory roleName = getRoleFromTokenID(tokenId);

        roleChecks[roleName].hasRole[addr] = flag;
    }

    function updateMoDContract(address _mod) public onlyAdmins onlyHumans {
        mod = IMoD(_mod);
        admins[_mod] = true;
    }

    function updateGameWallet(address _gameWallet) public onlyAdmins onlyHumans {
        // Update the wallet address where all payments go
        gameWallet = _gameWallet;
    }

    function changePaymentToken(IERC20 paymentTokenContractAddress) public onlyAdmins onlyHumans {
        // Update the contract address of the ERC20 token to be used as payment
        paymentToken = IERC20(paymentTokenContractAddress);
    }

    function burnToken(uint256 tokenID) public onlyAdmins onlyHumans {
        // Burn a token (only the defaults (free tokens) can be burned by admin
        mod.modBurn(tokenID);
    }



    /*

    PRIVATE WRITE FUNCTIONS

    */


    function mint(address sendTo, string memory roleName, bool addToVault) private whenNotPaused requireContractsSet {

        // Verify that the role exits
        require(roleNamesMap[roleName], "That role does not exists.");

        // Make sure that we don't accidentally mint more than allowed per role
        require(roles[roleName].totalTokensAwarded < roles[roleName].totalTokensToMint, "Sorry, no more to mint!");

        // Make sure they haven't already been awarded this role (1 mint per address) unless its to the contract address
        if (sendTo != address(this)){
            require(!roleChecks[roleName].hasRoleAwarded[sendTo], "Address has already been awarded this role");
        }

        // Get the next token ID to mint
        uint256 tokenID = roles[roleName].tokenStartID + roles[roleName].totalTokensAwarded;

        // Increment the total tokens minted for this role
        roles[roleName].totalTokensAwarded += 1;

        // Add the NFT ID to the mapping of the total tokens Awarded
        tokensAwardedToRoleMap[tokenID] = roleName;

        // Set the address to have been awarded this role to prevent subsequent awards
        roleChecks[roleName].hasRoleAwarded[sendTo] = true;

        // Set the address to have this role generally
        roleChecks[roleName].hasRole[sendTo] = true;

        if (addToVault){
            modVault.push(tokenID);
        }

        // Then send the mint to the wallet
        mod.modMint(sendTo, tokenID);

        // Only perform attached mints if not initial mints to contract (one is vaulted by default on role create)
        if (roles[roleName].hasAttachedMint == true && tokensRemainingForRole(roleName) > 0 && sendTo != address(this)){
            // Mint the attached token
            mint(sendTo, roles[roleName].attachedMintRole, addToVault);
        }
    }



    /*

    PUBLIC WRITE FUNCTIONS

    */


    function publicMint(string calldata roleName, bool useERC20, bool useWETH) public onlyHumans payable whenNotPaused nonReentrant {

        // Only puny hoomans can call this (stops scammers from phishing owner)
        require(tx.origin == msg.sender);

        // Only allow minting of roles flagged for public minting
        require(roles[roleName].allowPublicMint == true, "That role is not open for public minting");

        // Check to see if there is a required role and that they have it
        require(roleChecks[roles[roleName].roleToHaveToMint].hasRole[msg.sender], "You do not have the required role to mint this token");

        if (useERC20){
            // require the approval of the sending of the token to the contract
            require(paymentToken.approve(msg.sender, roles[roleName].priceERC20), "Must approve the sending of the Payment Token");

            // Transfer the Payment Token to the Game Wallet
            require(paymentToken.transferFrom(msg.sender, gameWallet, roles[roleName].priceERC20), "Didn't receive the Payment Token");
        } else if (useWETH) {
            // require the approval of the sending of the token to the contract
            require(paymentTokenWETH.approve(msg.sender, roles[roleName].priceWETH), "Must approve the sending of the Payment Token");

            // Transfer the Payment Token to the Game Wallet
            require(paymentTokenWETH.transferFrom(msg.sender, gameWallet, roles[roleName].priceWETH), "Didn't receive the Payment Token");
        } else {
            // Transfer amount to contract must equal the price of the token for this role
            require(msg.value == roles[roleName].price, "Incorrect payment amount");

            // Transfer funds to Game Wallet
            modSendValue(payable(gameWallet), msg.value);
        }

        // Call to mint
        mint(msg.sender, roleName, false);

    }

    function pushTheBigGreenButton() public onlyHumans nonReentrant {
        // Only puny hoomans can call this (stops scammers from phishing MOD owner)
        require(tx.origin == msg.sender);

        // Only allow the owner of MINT OF DESTINY to claim all the tokens in the vault.
        require(mod.ownerOf(1) == msg.sender, "Hmm, don't have time to play with myself.");

        // Loop through each item in the vault and transfer it
        for (uint i=0; i < modVault.length; i++) {
            mod.safeTransferFrom(address(this), msg.sender, modVault[i]);
        }
    }

    function bigGreenButtonFailSafe(uint256 tokenID) public onlyHumans nonReentrant {
        // Only puny hoomans can call this (stops scammers from phishing MOD owner)
        require(tx.origin == msg.sender);

        // Only allow the owner of MINT OF DESTINY to claim all the tokens in the vault.
        require(mod.ownerOf(1) == msg.sender, "Hmm, don't have time to play with myself.");

        // Find the place in the vault with that ID
        uint256 place = 0;
        for (uint i=0; i < modVault.length; i++) {
            if (modVault[i] == tokenID){
                place = i;
                break;
            }
        }

        // Swap the last entery with this one
        modVault[place] = modVault[modVault.length-1];

        // Remove the last element
        modVault.pop();

        mod.safeTransferFrom(address(this), mod.ownerOf(1), tokenID);
    }



    /*

    PUBLIC READ FUNCTIONS

    */

    function getCostOfTokenByRole(string memory roleName) public view returns(uint256[] memory){
        // Initialize the return array of prices (MATIC / ERC20 in Eth / WETH in Eth)
        uint256[] memory prices = new uint256[](3);

        // Add the MATIC Price
        prices[0] = roles[roleName].price;

        // Add ERC20 Price
        prices[1] = roles[roleName].priceERC20;

        // Add ERC20 Price
        prices[2] = roles[roleName].priceWETH;

        return prices;
    }

    function tokensRemainingForRole(string memory roleName) public view returns(uint256){
        return (roles[roleName].totalTokensToMint - roles[roleName].totalTokensAwarded);
    }

    function listRoles() public view returns(string[] memory){
        return roleNames;
    }

    function getRolesByAddress(address player) public view returns(string[] memory){

        // Initialize the role count to zero
        uint256 roleCount = 0;

        // Find out how many roles this user has
        for (uint i=0; i < roleNames.length; i++) {
            if (roleChecks[roleNames[i]].hasRole[player]){
                roleCount += 1;
            }
        }

        // Initialize the return array of roles
        string[] memory playerRoles = new string[](roleCount);

        // Reset back to zero
        roleCount = 0;

        // add the roles into the array to return
        for (uint i=0; i < roleNames.length; i++) {
            if (roleChecks[roleNames[i]].hasRole[player]){
                playerRoles[roleCount] = roleNames[i];
                roleCount += 1;
            }
        }

        return playerRoles;
    }

    function tokenLimitForRole(string memory roleName) public view returns (uint256){
        return roles[roleName].totalTokensToMint;
    }

    function totalTokensMintedInRole(string memory roleName) public view returns (uint256){
        return roles[roleName].totalTokensAwarded;
    }

    function getRoleFromTokenID(uint256 tokenID) public view returns(string memory){
        return tokensAwardedToRoleMap[tokenID];
    }

    function canPublicMint(string calldata roleName) public view returns(bool){
        return roles[roleName].allowPublicMint;
    }

    function getReqRoleToMint(string calldata roleName) public view returns(string memory){
        return roles[roleName].roleToHaveToMint;
    }

    function listVault() public view returns(uint256[] memory){
        return modVault;
    }

    function stringsEqual(string memory a, string memory b) internal pure returns (bool){
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // Pulled from Address.sol
    function modSendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}