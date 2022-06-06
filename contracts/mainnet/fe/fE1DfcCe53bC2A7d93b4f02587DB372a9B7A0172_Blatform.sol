// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.4;

import "BlatformBase.sol";

/// @custom:security-contact [email protected]
contract Blatform is  BlatformBase {
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

    mapping(address => Balance) private userBalances;
    address[] private owners;
    mapping(address => Phased[]) private userPhased;
    /// Total Supply of Blatform Token
    uint256  private totalClaim  = 0;

   
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() ERC20("Blatform Token", "BFORM") {

        totalClaim = 1000000000 * 10**18;
        _mint(address(this), totalClaim);
        transferOwnership(msg.sender);
    }
    
 


    
    /**
     * @dev Adding the addresses of the people who bought in the ICO sale to the contract.
     *
     */
    function addOwnedUsers(address[] memory userAddress, uint256[] memory amount, string[] memory role) external {
        bool IsSafe = addressIsSafe(msg.sender);
        require(IsSafe, "Not safe address");
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
        bool toIsSafe = addressIsSafe(to);
       
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
        if (msg.sender == getContractAddress("SP")) {
            _transfer(from,to,amount);
        }
    }
 
    /**
    *  @dev Airdrop function
    **/
    function airDrop(uint amount, address to) external {
        require(msg.sender == getContractAddress("MP"), "Only marketing account can trigger a Air Drop");
        if (userBalances[to].isValue == false) {
            userBalances[to].isValue = true;
            userBalances[to].user = to;
        } 
         _transfer(msg.sender,to,amount);
    }
    function addOwnedUser(address userAddress, uint256 amount, string memory role) external {
        bool isSafe = addressIsSafe(msg.sender);

        require(isSafe, "You don't have a access this action");
        userBalances[userAddress] = Balance(userAddress, amount, 0, true, role);
        owners.push(userAddress);
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
        bool isSafe=addressIsSafe(msg.sender);

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
        bool isSafe=addressIsSafe(msg.sender);
        require(isSafe, "Only can call safe addresses" );

        bool isSafeContract=addressIsSafe(from);
        require(isSafeContract, "Only can call safe addresses" );
        
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
}