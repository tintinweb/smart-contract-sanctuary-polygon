//./contracts/PassportContract.sol

// SPDX-License-Identifier: SHELL
pragma solidity ^0.8.18;

error passportError(string message );
/**
 * @notice save and delete passport data
 */
contract PassportContract {

    uint8 private _initialized; // track top level call status
    bool private _initializing; // to prevent multiple intialization

    address private admin; // owner

    /**
     * @param data : encrypted data
     * @param passportId : unique indentifier
     * @param from : caller address
     * @param userSignature : signature data
     */
    struct Passport {
        string data;
        string passportId;
        address from;
        string userSignature;
    }

    mapping (string => Passport) passportRepo; // passport dictionary

    event Initialized(uint8 version);
    event OwnershipTransfered(address newOwner);
    event PassportEvent(string _hash, string indexed _passportId, string _stringPassportId, uint256 indexed _timestamp, address _from, string _userSignature);
    error passportNotFound();
    /**
     * @notice prerequisite for initializer to work as constractor
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    modifier ownerOnly() {
        require(msg.sender == admin, "Only owner have rights");
        _;
    }

    modifier notZeroAddress(address _admin){
        require(_admin != address(0), "Address should not be Zero Address");
        _;
    }

    // constractor function
    function initialize() public initializer{
        admin = msg.sender;
    }

    /**
     * @notice save passport data in @param passportRepo and emit a passportEvent
     * 
     * @param data encrypted data
     * @param passportId identifier
     * @param from caller address
     * @param userSignature signature data
     */
    function savePassportData(string memory data, string memory passportId, address from, string memory userSignature) public ownerOnly {
        // saving passport to passportRepo dictionary
        if(keccak256(bytes(passportId)) == keccak256(bytes(""))){
            revert passportError({message : "Passport Id can not be null"});
        }
        if(keccak256(bytes(data)) == keccak256(bytes(""))){
            // revert ("Data can not be null");
            revert passportError({message : "Data can not be null"});
        }
        if(keccak256(bytes(userSignature)) == keccak256(bytes(""))){
            revert passportError({message : "User Signature can not be null"});
        }
        passportRepo[passportId] = Passport(data, passportId, from, userSignature);
        // event emitting
        emit PassportEvent(data, passportId, passportId, block.timestamp, from, userSignature);
    }

    /**
     * get passport data
     * @param passportId identifier
     */
    function getPassportData(string memory passportId) public view returns(Passport memory) {
        if(passportRepo[passportId].from == address(0)){
            revert passportNotFound();
        }
        else{
        return passportRepo[passportId];
        }
    }

    /**
     *  change owner address
     * @param newAdmin new owner address 
     */
    function transferAdminRights(address newAdmin) public ownerOnly notZeroAddress(newAdmin){
        require(newAdmin != admin, "New admin cannot be current admin");
        admin = newAdmin;
        emit OwnershipTransfered(admin);

    }

    /**
     *  delete passport 
     * @param passportId identifier
     * 
     * @return Passport deleted passport
     */
    function removePassportData(string memory passportId) public ownerOnly returns (Passport memory) {
        Passport memory deletedPassport = passportRepo[passportId]; // temporary passport only persist while function is called
        delete passportRepo[passportId];
        return deletedPassport;
    }

    /**
     * get current smart contract version
     */
    function getContractVersion() public pure returns (string memory) {
        return "0.3.0";
    }
}