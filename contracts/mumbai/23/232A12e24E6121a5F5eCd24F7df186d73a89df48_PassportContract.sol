//./contracts/PassportContract.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
    struct passport {
        string data;
        string passportId;
        address from;
        string userSignature;
    }

    mapping (string => passport) passportRepo; // passport dictionary

    event Initialized(uint8 version);
    event passportEvent(string _hash, string indexed _passportId, string _stringPassportId, uint256 indexed _timestamp, address _from, string _userSignature);
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
     * @param _data encrypted data
     * @param _passportId identifier
     * @param _from caller address
     * @param _userSignature signature data
     */
    function savePassportData(string memory _data, string memory _passportId, address _from, string memory _userSignature) public ownerOnly {
        // saving passport to passportRepo dictionary
        if(keccak256(bytes(_passportId)) == keccak256(bytes(""))){
            revert passportError({message : "Passport Id can not be null"});
        }
        if(keccak256(bytes(_data)) == keccak256(bytes(""))){
            // revert ("Data can not be null");
            revert passportError({message : "Data can not be null"});
        }
        if(keccak256(bytes(_userSignature)) == keccak256(bytes(""))){
            revert passportError({message : "User Signature can not be null"});
        }
        passportRepo[_passportId] = passport(_data, _passportId, _from, _userSignature);
        // event emitting
        emit passportEvent(_data, _passportId, _passportId, block.timestamp, _from, _userSignature);
    }

    /**
     * get passport data
     * @param _passportId identifier
     */
    function getPassportData(string memory _passportId) public view returns(passport memory) {
        if(passportRepo[_passportId].from == address(0)){
            revert passportNotFound();
        }
        else{
        return passportRepo[_passportId];
        }
    }

    /**
     *  change owner address
     * @param _admin new owner address 
     */
    function transferAdminRights(address _admin) public ownerOnly notZeroAddress(_admin){
        admin = _admin;
    }

    /**
     *  delete passport 
     * @param _passportId identifier
     * 
     * @return passport deleted passport
     */
    function removePassportData(string memory _passportId) public ownerOnly returns (passport memory) {
        passport memory deletedPassport = passportRepo[_passportId]; // temporary passport only persist while function is called
        delete passportRepo[_passportId];
        return deletedPassport;
    }

    /**
     * get current smart contract version
     */
    function getContractVersion() public pure returns (string memory) {
        return "0.3.0";
    }
}