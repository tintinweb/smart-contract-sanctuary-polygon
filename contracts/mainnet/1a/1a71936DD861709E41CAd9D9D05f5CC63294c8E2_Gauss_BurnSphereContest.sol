/**
 *Submitted for verification at polygonscan.com on 2022-07-03
*/

// Provides information about the current execution context, including the sender of the transaction and its data.
abstract contract Context {

    // Empty initializer, to prevent people from mistakenly deploying an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



// Provides a basic access control mechanism, where an account '_owner' can be granted exclusive access to specific functions by using the modifier `onlyOwner`.
abstract contract Ownable is Context {

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Initializes the contract, setting the deployer as the initial owner.
    constructor() {
        _transferOwnership(_msgSender());
    }

    // Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    // Internal function, transfers ownership of the contract to a new account (`newOwner`).
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



// ERC20 Interface that creates basic functions for a ERC20 token.
interface IERC20 {

    // Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    // Returns the token decimals.
    function decimals() external view returns (uint8);

    // Returns the token symbol.
    function symbol() external view returns (string memory);

    // Returns the token name.
    function name() external view returns (string memory);

    // Returns balance of the referenced 'account' address.
    function balanceOf(address account) external view returns (uint256);

    // Transfers an 'amount' of tokens from the caller's account to the referenced 'recipient' address. Emits a {Transfer} event. 
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Transfers an 'amount' of tokens from the 'sender' address to the 'recipient' address. Emits a {Transfer} event.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Returns the remaining tokens that the 'spender' address can spend on behalf of the 'owner' address through the {transferFrom} function.
    function allowance(address _owner, address spender) external view returns (uint256);

    // Sets 'amount' as the allowance of 'spender' then returns a boolean indicating result of operation. Emits an {Approval} event.
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    // Sets 'amount' as the allowance of 'spender' then returns a boolean indicating result of operation. Emits an {Approval} event.
    function approve(address spender, uint256 amount) external returns (bool);

    // Emitted when `value` tokens are moved from one account address (`from`) to another (`to`). Note that `value` may be zero.
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `value` is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/*  _____________________________________________________________________________

    Gauss: Sphere Burn Contest


    MIT License. (c) 2022 Gauss Gang Inc. 

    _____________________________________________________________________________
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;


/*  This contract is a Sphere Token Burn Contest run by Gauss. Anyone who wishes to participate in the contest must interact with
    contract using the "contestEntry" function and entering the amount of Sphere you wish to burn. At the end of the contest, we
    will close the and determine a winner; results will announce on the Gauss discord server.

        * Each 1000 Sphere will count as ONE Entry. 
*/
contract Gauss_BurnSphereContest is Ownable {

    // Mapping that contains an ID number associated with an wallet address.
    mapping(uint256 => address) private contestantWallets;

    // Mapping that contains the ID number of each "contestant" and the amount of Sphere they have burned.
    mapping(uint256 => uint256) private burnTotals;

    // Mapping that will hold the ID number and entry amount for each Contestant.
    mapping(uint256 => uint256) private entryTotals;
    
    // The Sphere token being burned.
    IERC20 private _sphereToken;

    // Admin address to send left over MATIC to.
    address payable public adminWallet;

    // Dead Address where Sphere will be sent to burn.
    address public burnWallet;

    // Total amount of Sphere to be burned.
    uint256 public totalBurned;

    // Total number of Contestants.
    uint256 public totalContestants;

    // End timestamp, the time the contest ends.
    uint256 public endTime;

    // A varaible to determine whether Crowdsale is closed or not.
    bool private _closed;


    // Constructor sets takes the variables passed in and initializes state variables. 
    constructor() {
        endTime = 1657746000; // July 13th 5pm EDT
        _sphereToken = IERC20(0x62F594339830b90AE4C084aE7D223fFAFd9658A7);
        adminWallet = payable(0x206F10F88159590280D46f607af976F6d4d79Ce3);
        burnWallet = 0x000000000000000000000000000000000000dEaD;
        totalContestants = 0;
        _closed = false;
    }


    // Receive function to recieve MATIC.
    receive() external payable {

        // Allows owner to fill contract with MATIC to cover gas costs.
        if (msg.sender == owner()) {}
    }


    //  Allows one to burn Sphere tokens.
    function enterContest(uint256 sphereAmount) external payable {
        address senderWallet = msg.sender;
        _validateEntry(senderWallet, sphereAmount);
        _processBurnEntry(senderWallet, sphereAmount);
    }


    // Validation of an incoming Entry. Uses require statements to revert state when conditions are not met.
    function _validateEntry(address senderWallet, uint256 sphereAmount) internal view {
        require(block.timestamp < endTime, "Gauss_SphereBurnContest: current time is after the end of the Burn Contest.");
        require(_closed == false, "Gauss_SphereBurnContest: Contest is no longer open.");
        require(senderWallet != address(0), "Gauss_SphereBurnContest: sender can not be Zero Address.");
        require(sphereAmount != 0, "Gauss_SphereBurnContest: amount of Sphere must be greater than 0.");
    }


    // Processes the Sphere Burn Entry by determining the number of entries and sending over the 
    function _processBurnEntry(address _sender, uint256 _sphereAmount) internal {

        require(_sphereToken.allowance(_sender, address(this)) >= (_sphereAmount * (10**18)), "Allowance is too low, please increase the allowance for the Burn Contract before sending tokens.");
        require(_sphereToken.transferFrom(_sender, address(this), (_sphereAmount * (10**18))), "Unable to transfer Sphere to Burn contract.");

        // Calculates the contest entry amount using the "sphereAmount" divided by 1000.
        uint256 entryAmount = (_sphereAmount/1000);

        // Adds the contestant wallet address to the mapping of each ID number.
        contestantWallets[totalContestants] = _sender;        

        // Adds the entry amount to the mapping of each contestants address.
        entryTotals[totalContestants] = entryAmount;

        // Adds the "sphereAmount" to the mapping of each contestants address.
        burnTotals[totalContestants] = _sphereAmount;

        // Updates the number of total Sphere burned and total Contestants.
        totalBurned += _sphereAmount;
        totalContestants += 1;
    }


    // Returns a receipt showing each Contestants's wallet address, the amount of Sphere Burned, and the amount of Entries gained.
    function getReceipts() external view onlyOwner() returns (address[] memory, uint256[] memory, uint256[] memory) {
        
        // Creates memory arrays for the wallets, sphere amounts, and entries for each transaction.
        address[] memory wallets = new address[](totalContestants);
        uint256[] memory sphereBurned = new uint256[](totalContestants);
        uint256[] memory entries = new uint256[](totalContestants);

        for (uint256 i = 0; i < totalContestants; i++) {
            wallets[i] = contestantWallets[i];
            sphereBurned[i] = burnTotals[i];
            entries[i] = entryTotals[i];
        }

        return (wallets, sphereBurned, entries);
    }


    // Allows owner to close the Contest.
    function closeContest() public onlyOwner() {
        _closed = true;
    }

    
    /*  Determines the winner of the contest by using the current time as a seed in creating a hash, then converted to an integer,
        and finally a number between 0 and the Total Number of Contestants is chosen after using a modulo operator with the converted integer.

            * Normally, this would not be the best method to get a sudo-random number, especially if the function were public.
              As this is protected by an onlyOwner modifier and the fact that no one will know the exact time
              in which we will call this function (us included), this method is sufficient against a block.timestamp attack on 
              a faster PoS blockchain like Polygon where the block.timestamp will be frequently updated with each new block.
    */
    function determineWinner() external view onlyOwner() returns (address) {
        require(_closed == true, "Gauss_SphereBurnContest: contest has not been closed.");
        require(totalContestants != 0, "Gauss_SphereBurnContest: there are no recorded contestants.");
        
        uint256 winnerID = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % totalContestants;

        return contestantWallets[winnerID];
    }


    // Batch release function that will transfer all Sphere tokens to the burn wallet; can only be called by owner.
    function burnAllTokens() external payable onlyOwner() {

        require(_closed == true, "Gauss_SphereBurnContest: contest has not been closed.");
        
        require(_sphereToken.transfer(burnWallet, _sphereToken.balanceOf(address(this))));
    }


    /*  Transfer remaining Sphere tokens back to the "adminWallet" as well as any MATIC that may be left in the contract.
            NOTE:   - To be called at end of the Contest to finalize and complete the Contest.
                    - Can act as a backup in case the Contest needs to be urgently stopped.
                    - Care should be taken when calling function as it could prematurely end the Contest if accidentally called. */
    function finalizeContest() public payable onlyOwner() {

        // Send remaining tokens back to the admin.
        _sphereToken.transfer(adminWallet, _sphereToken.balanceOf(address(this)));

        // Transfers any MATIC that may be left in contract back to the admin.
        adminWallet.transfer(address(this).balance);

        closeContest();
    }
}