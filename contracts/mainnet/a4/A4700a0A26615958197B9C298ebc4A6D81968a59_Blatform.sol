// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import "ERC20.sol";
import "Ownable.sol";


/// @custom:security-contact [email protected]
contract Blatform is  ERC20 , Ownable {

    struct UserBalanceHistory {
        int256 amount;
        uint date;
    }
    struct  Balance {
        address user;
        uint256 total;
        uint256 released;
        bool isValue;
        string role;
    }
    struct Phased {
        string name;
        string role;
    }
    address  private _token;

    event PaymentReceived(address from, uint256 amount);
    mapping(address => Balance) private userBalances;
    address[] private owners;
    mapping(address => Phased[]) private userPhased;
    /// Total Supply of Blatform Token
    uint256  private totalClaim  = 0;

    /// Staking Pool share percentage and address setting.
    address  private stakingPoolAddress = 0x0000000000000000000000000000000000000000;
    uint  private stakingPoolPercent = 340000;

    /// Development Pool share percentage and address setting.
    address  private developmentPoolAddress = 0x0000000000000000000000000000000000000000;
    uint  private developmentPoolPercent = 240000;

    /// Platform Operations share percentage and address setting.
    address  private platformOperationsPoolAddress = 0x0000000000000000000000000000000000000000;
    uint  private platformOperationsPoolPercent = 90000;

    /// Team & Aadvisors share percentage and address setting.
    address  private teamAndAdvisorsPoolAddress = 0x0000000000000000000000000000000000000000;
    uint  private teamAndAdvisorsPoolPercent = 150000;

    /// Marketing share percentage and address setting.
    address  private marketingPoolAddress = 0x0000000000000000000000000000000000000000;
    uint  private marketingPoolPercent = 30000;

    /// Customer Incentives share percentage and address setting.
    address  private customerInventivePoolAddress = 0x0000000000000000000000000000000000000000;
    uint  private customerInventivePoolPercent = 100000;

    /// ICO Private Sales share percentage and address setting.
    address  private icoPoolAddress = 0x0000000000000000000000000000000000000000;
    uint  private icoPoolPercent = 28000;

    /// After Listing Sales share percentage and address setting.
    address  private alsPoolAddress = 0x0000000000000000000000000000000000000000;
    uint  private alsPoolPercent = 11000;

    address private empty = 0x0000000000000000000000000000000000000000;
    /// Swap Sales share percentage and address setting.
    address  private swapPoolAddress = 0x0000000000000000000000000000000000000000;
    uint  private swapPoolPercent = 11000;

    address[]  private safeAddresses;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() ERC20("Blatform Token", "BFORM") {

        totalClaim = 1000000000 * 10**18;
        safeAddresses = [
            address(this),
            icoPoolAddress,
            marketingPoolAddress,
            customerInventivePoolAddress,
            alsPoolAddress,
            teamAndAdvisorsPoolAddress,
            developmentPoolAddress,
            stakingPoolAddress,
            swapPoolAddress,
            0x0000000000000000000000000000000000000000
        ];
        _mint(address(this), totalClaim);
        transferOwnership(msg.sender);

    }
    /**
     * @dev wrote this part to provide safe string matching
     *
     */
    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /**
     * @dev Setting up pool contracts
     *
     */
    function setPoolAddress(address[] memory poolAddress, string[] memory poolTypes) external onlyOwner {
        for(uint i=0;i<poolAddress.length;i++) {
            /// Eğer daha önce set edildiyse değiştirmeye izin vermiyoruz.
            if (compareStrings(poolTypes[i],"SWP") && swapPoolAddress == empty) {
                swapPoolAddress = poolAddress[i];
            } else if (compareStrings(poolTypes[i],"ICO") && icoPoolAddress == empty) {
                icoPoolAddress = poolAddress[i];
            } else if (compareStrings(poolTypes[i],"ALS") && alsPoolAddress == empty) {
                alsPoolAddress = poolAddress[i];
            } else if (compareStrings(poolTypes[i],"CI") && customerInventivePoolAddress == empty) {
                customerInventivePoolAddress = poolAddress[i];
            } else if (compareStrings(poolTypes[i],"MP") && marketingPoolAddress == empty) {
                marketingPoolAddress = poolAddress[i];
            } else if (compareStrings(poolTypes[i],"TA") && teamAndAdvisorsPoolAddress == empty) {
                teamAndAdvisorsPoolAddress = poolAddress[i];
            } else if (compareStrings(poolTypes[i],"PA") && platformOperationsPoolAddress == empty) {
                platformOperationsPoolAddress = poolAddress[i];
            } else if (compareStrings(poolTypes[i],"DEV") && developmentPoolAddress == empty) {
                developmentPoolAddress = poolAddress[i];
            } else if (compareStrings(poolTypes[i],"SP") && stakingPoolAddress == empty) {
                stakingPoolAddress = poolAddress[i];
            } else {
                revert("Can't find contract");
            }
        }
        /// Whitelisting safe transfer addresses under safe addresses
        safeAddresses = [
            address(this),
            icoPoolAddress,
            marketingPoolAddress,
            customerInventivePoolAddress,
            alsPoolAddress,
            teamAndAdvisorsPoolAddress,
            developmentPoolAddress,
            stakingPoolAddress,
            swapPoolAddress,
            0x0000000000000000000000000000000000000000
        ];
    }

     function transferTokenForUpdate(address oldAddress,string memory poolTypes) external {
         if (compareStrings(poolTypes,"SWP")) {
                require(msg.sender == swapPoolAddress, "You don't have access this method");
                _transfer(oldAddress,swapPoolAddress,balanceOf(oldAddress));
            } else if (compareStrings(poolTypes,"ICO")) {
                require(msg.sender == icoPoolAddress, "You don't have access this method");
                _transfer(oldAddress,icoPoolAddress,balanceOf(oldAddress));
            } else if (compareStrings(poolTypes,"ALS")) {
                require(msg.sender == alsPoolAddress, "You don't have access this method");
                _transfer(oldAddress,alsPoolAddress,balanceOf(oldAddress));
            } else if (compareStrings(poolTypes,"CI")) {
                require(msg.sender == customerInventivePoolAddress, "You don't have access this method");
                _transfer(oldAddress,customerInventivePoolAddress,balanceOf(oldAddress));
            } else if (compareStrings(poolTypes,"MP")) {
                require(msg.sender == marketingPoolAddress, "You don't have access this method");
                _transfer(oldAddress,marketingPoolAddress,balanceOf(oldAddress));
            } else if (compareStrings(poolTypes,"TA")) {
                require(msg.sender == teamAndAdvisorsPoolAddress, "You don't have access this method");
                _transfer(oldAddress,teamAndAdvisorsPoolAddress,balanceOf(oldAddress));
            } else if (compareStrings(poolTypes,"PA")) {
                require(msg.sender == platformOperationsPoolAddress, "You don't have access this method");
                _transfer(oldAddress,platformOperationsPoolAddress,balanceOf(oldAddress));
            } else if (compareStrings(poolTypes,"DEV")) {
                require(msg.sender == developmentPoolAddress, "You don't have access this method");
                _transfer(oldAddress,developmentPoolAddress,balanceOf(oldAddress));
            } else if (compareStrings(poolTypes,"SP")) {
                require(msg.sender == stakingPoolAddress, "You don't have access this method");
                _transfer(oldAddress,stakingPoolAddress,balanceOf(oldAddress));
            } else {
                revert("Can't find contract");
            }
     }
     function setPoolAddressUpdate(string memory poolTypes) external {

            if (compareStrings(poolTypes,"SWP")) {
                require(msg.sender == swapPoolAddress, "You don't have access this method");
                swapPoolAddress = empty;
            } else if (compareStrings(poolTypes,"ICO")) {
                require(msg.sender == icoPoolAddress, "You don't have access this method");
                icoPoolAddress = empty;
            } else if (compareStrings(poolTypes,"ALS")) {
                require(msg.sender == alsPoolAddress, "You don't have access this method");
                alsPoolAddress = empty;
            } else if (compareStrings(poolTypes,"CI")) {
                require(msg.sender == customerInventivePoolAddress, "You don't have access this method");
                customerInventivePoolAddress = empty;
            } else if (compareStrings(poolTypes,"MP")) {
                require(msg.sender == marketingPoolAddress, "You don't have access this method");
                marketingPoolAddress = empty;
            } else if (compareStrings(poolTypes,"TA")) {
                require(msg.sender == teamAndAdvisorsPoolAddress, "You don't have access this method");
                teamAndAdvisorsPoolAddress = empty;
            } else if (compareStrings(poolTypes,"PA")) {
                require(msg.sender == platformOperationsPoolAddress, "You don't have access this method");
                platformOperationsPoolAddress = empty;
            } else if (compareStrings(poolTypes,"DEV")) {
                require(msg.sender == developmentPoolAddress, "You don't have access this method");
                developmentPoolAddress = empty;
            } else if (compareStrings(poolTypes,"SP")) {
                require(msg.sender == stakingPoolAddress, "You don't have access this method");
                stakingPoolAddress = empty;
            } else {
                revert("Can't find contract");
            }

    }

    function setNewPoolAddressUpdate(address addr, string memory poolTypes) external {

            if (compareStrings(poolTypes,"SWP")) {
                require(msg.sender == swapPoolAddress, "You don't have access this method");
                swapPoolAddress = addr;
            } else if (compareStrings(poolTypes,"ICO")) {
                require(msg.sender == icoPoolAddress, "You don't have access this method");
                icoPoolAddress = addr;
            } else if (compareStrings(poolTypes,"ALS")) {
                require(msg.sender == alsPoolAddress, "You don't have access this method");
                alsPoolAddress = addr;
            } else if (compareStrings(poolTypes,"CI")) {
                require(msg.sender == customerInventivePoolAddress, "You don't have access this method");
                customerInventivePoolAddress = addr;
            } else if (compareStrings(poolTypes,"MP")) {
                require(msg.sender == marketingPoolAddress, "You don't have access this method");
                marketingPoolAddress = addr;
            } else if (compareStrings(poolTypes,"TA")) {
                require(msg.sender == teamAndAdvisorsPoolAddress, "You don't have access this method");
                teamAndAdvisorsPoolAddress = addr;
            } else if (compareStrings(poolTypes,"PA")) {
                require(msg.sender == platformOperationsPoolAddress, "You don't have access this method");
                platformOperationsPoolAddress = addr;
            } else if (compareStrings(poolTypes,"DEV")) {
                require(msg.sender == developmentPoolAddress, "You don't have access this method");
                developmentPoolAddress = addr;
            } else if (compareStrings(poolTypes,"SP")) {
                require(msg.sender == stakingPoolAddress, "You don't have access this method");
                stakingPoolAddress = addr;
            } else {
                revert("Can't find contract");
            }

    }
     /**
     * @dev Adjustment of balances of ICO sales made before token minting.
     *
     */
     function addOwnedUser(address userAddress, uint256 amount, string memory role) external {
        bool isSafe = false;
        for(uint i=0; i<safeAddresses.length; i++) {
            if (msg.sender == safeAddresses[i]) {
                isSafe = true;
            }
        }
        require(isSafe, "You don't have a access this action");
        userBalances[userAddress] = Balance(userAddress, amount, 0, true, role);
        owners.push(userAddress);
    }

    /**
     * @dev Adding the addresses of the people who bought in the ICO sale to the contract.
     *
     */
    function addOwnedUsers(address[] memory userAddress, uint256[] memory amount, string[] memory role) external onlyOwner {
        for (uint i=0;i<userAddress.length; i++) {
            userBalances[userAddress[i]] = Balance(userAddress[i], amount[i], 0, true, role[i]);
            owners.push(userAddress[i]);
        }
    }
    /**
     * @dev While transferring tokens, we intervene and perform user checks. If it is on the safe list, we pass the checks.
     *
     */
    function _beforeTokenTransfer(address from, address to, uint256 value) internal virtual override {
        bool isSafe = false;
        bool toIsSafe = false;
        for(uint i=0; i<safeAddresses.length; i++) {
            if (from == safeAddresses[i]) {
                isSafe = true;
            }
            if (to == safeAddresses[i]) {
                toIsSafe = true;
            }
        }
        if (isSafe == false) {

            require(userBalances[from].isValue, "Sender can't found");
            require(balanceOf(from) >= value, "Insufficient released balance");
        }
        if (toIsSafe == false) {
            if (userBalances[to].isValue == false) {
                userBalances[to].user = to;
                userBalances[to].isValue = true;
                userBalances[to].released = value;
                userBalances[to].total = value;

            }
        }
        super._beforeTokenTransfer(from, to , value);
    }

    /**
     * @dev Checking balances of addresses.
     *
     */
    function balanceOfTotal(address account) external view returns (uint256) {
        if (account == 0x0000000000000000000000000000000000000000) {
            return totalClaim;
        }
        return userBalances[account].total;
    }
    /**
     * @dev Checking users existence inside the system
     *
     */
    function isUser(address account) external view returns (bool) {
        return userBalances[account].isValue;
    }
    /**
     * @dev Function allows ICO token holders to check the amount of their released tokens.
     *
     */
    function balanceOfUsable(address account) external view  returns (uint256) {
        return userBalances[account].released;
    }
    /**
     * @dev Ownership control of staking addresses.
     *
     */
    function transferStake(address from , address to, uint amount) external {
        if (msg.sender == stakingPoolAddress) {
            _transfer(from,to,amount);
        }
    }

    /**
    *  @dev Airdrop function
    **/
    function airDrop(uint amount, address to) external {
        require(msg.sender == marketingPoolAddress, "Only marketing account can trigger a Air Drop");
        if (userBalances[to].isValue == false) {
            userBalances[to].isValue = true;
            userBalances[to].user = to;
        } 
         _transfer(msg.sender,to,amount);
    }

    /**
    * @dev user is phased a phase
    */
    function isUserReleasedPhase(address user, string memory phase, string memory role) virtual internal returns (bool) {
        bool phased = false;
        for (uint i=0;i<userPhased[user].length;i++) {
            if (compareStrings(userPhased[user][i].name , phase) && compareStrings(userPhased[user][i].role, role)) {
                phased = true;
            }
        }
        return phased;
    }

    function release () external onlyOwner {}

    function releasedList(address user) external view returns (Phased[] memory){
        return userPhased[user];
    }


    function userRelease(uint percent, string memory role , string memory phase, address to) external  {
        bool isSafe=false;
        for(uint i=0; i<safeAddresses.length; i++) {
            if (msg.sender == safeAddresses[i]) {
                isSafe = true;
            }
        }
        require(isSafe, "Only can call safe addresses" );
        if (compareStrings(userBalances[to].role, role) && isUserReleasedPhase(to,phase,role) == false) {
            uint released =  (userBalances[to].total / 1000) * (percent / 100)  + userBalances[to].released;
            require(userBalances[to].total  >= released, "Something wrong!");

            _transfer(msg.sender, to, (userBalances[to].total / 1000) * (percent / 100) );
            userBalances[to].released  = released;
            userPhased[to].push(Phased(phase,role));
        }
    }


    /**
     * @dev When the release period of the person whose phase sale has been made, the safe contract runs this function.
     *
     */
    function userReleases(uint percent, address from , string memory role, string memory phase) external  {
        bool isSafe=false;
        for(uint i=0; i<safeAddresses.length; i++) {
            if (from == safeAddresses[i]) {
                isSafe = true;
            }
        }
        require(isSafe, "Only can call safe addresses" );
        for (uint i=0; i < owners.length; i++) {
            if (compareStrings(userBalances[owners[i]].role, role) && isUserReleasedPhase(owners[i],phase,role) == false) {
                uint released =  (userBalances[owners[i]].total / 1000) * (percent / 100)  + userBalances[owners[i]].released;
                require(userBalances[owners[i]].total  >= released, "Something wrong!");

                _transfer(from, owners[i], (userBalances[owners[i]].total / 1000) * (percent / 100) );
                userBalances[owners[i]].released  = released;
                userPhased[owners[i]].push(Phased(phase,role));
            }
        }
    }
    /**
     * @dev It loads balances to the main contracts by running it as an initial function.
     *
     */
    function releasePool() external onlyOwner {


        /// Staking Pool Claim
        if (stakingPoolAddress != empty) _transfer(address(this), stakingPoolAddress, (totalClaim / 1000) * (stakingPoolPercent / 1000) );

        /// Development Pool Claim
        if (developmentPoolAddress != empty) _transfer(address(this), developmentPoolAddress, (totalClaim / 1000) * (developmentPoolPercent / 1000) );
         /// Operation Claim
        if (platformOperationsPoolAddress != empty) _transfer(address(this), platformOperationsPoolAddress, (totalClaim / 1000) * (platformOperationsPoolPercent / 1000) );


        /// Marketing Claim
        if (marketingPoolAddress != empty) _transfer(address(this), marketingPoolAddress, (totalClaim / 10000) * (marketingPoolPercent / 100) );
        /// Customer Incentives Claim
        if (customerInventivePoolAddress != empty) _transfer(address(this), customerInventivePoolAddress, (totalClaim / 10000) * (customerInventivePoolPercent / 100) );
         /// ICO Private Sales Claim
        if (icoPoolAddress != empty) _transfer(address(this), icoPoolAddress, (totalClaim / 10000) * (icoPoolPercent / 100) );

        /// After Listing Sales Claim
        if (alsPoolAddress != empty) _transfer(address(this), alsPoolAddress, (totalClaim / 10000) * (alsPoolPercent / 100) );
         /// Swap Sales Claim
        if (swapPoolAddress != empty) _transfer(address(this), swapPoolAddress, (totalClaim / 10000) * (swapPoolPercent / 100) );
        /// Team & Advisors Claim
        if (teamAndAdvisorsPoolAddress != empty) _transfer(address(this), teamAndAdvisorsPoolAddress, (totalClaim / 10000) * (teamAndAdvisorsPoolPercent / 100) );

 }
}