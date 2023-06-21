// SPDX-License-Identifier: SHELL
pragma solidity ^0.8.18;

contract AccessControl {

    // admin 
    address owner;

    mapping(string=>mapping(address=>mapping(bytes32=>bool))) organisation;

    modifier onlyOwner() {
        if (!(msg.sender == owner)) {
            revert("You can not set roles: unauthorized access");
        }
        _;
    }

    function assignRolesToOrgAddress(string memory orgId, address account, bytes32 [] memory roles) public onlyOwner{
        for (uint i = 0; i < roles.length; i++) {
            organisation[orgId][account][roles[i]]=true;
        }
    }
    function viewOwner()public view returns (address){
        return owner;
    }
    function setOwner(address newOnwer) public onlyOwner{
        owner = newOnwer;
    }
    function checkRoles(string memory orgname, address account, bytes32 role) public view returns(bool) {
       return organisation[orgname][account][role];
    }
}

//./contracts/PassportContract.sol

// SPDX-License-Identifier: SHELL
pragma solidity ^0.8.18;
import "./falconAccessControl.sol";

error passportError(string message);

/**
 * @notice save and delete passport data
 */
contract PassportContract is AccessControl {
    uint8 private _initialized; // track top level call status
    bool private _initializing; // to prevent multiple intialization

    /**
     * @param dataHash : encrypted data
     * @param passportId : unique indentifier
     * @param version : version detail
     * @param model : model number
     */
    struct Passport {
        string dataHash;
        string passportId;
        string version;
        string schemaModel;
    }

    mapping(string => Passport) passportRepo; // passport dictionary

    mapping(string=>mapping(address=>mapping(bytes32=>bool))) organisationBlackList;

    event Initialized(uint8 version);
    event OwnershipTransfered(address newOwner);

    event PassportEvent(
        string _dataHash,
        string indexed _passportId,
        string _stringPassportId,
        uint256 indexed _timestamp,
        string _model,
        string _version
    );
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
        require(msg.sender == owner, "Only owner have rights");
        _;
    }

    modifier notZeroAddress(address _admin) {
        require(_admin != address(0), "Address should not be Zero Address");
        _;
    }

    // constractor function
    function initialize() public initializer {
        owner = msg.sender;
    }

    /**
     * @notice save passport data in @param passportRepo and emit a passportEvent
     *
     * @param passportData : encrypted passport data
     * @param orgId : org identifier
     * @param role : role code
     */
    function createNewPassports(
        string memory orgId,
        bytes32 role,
        Passport[] memory passportData
    ) public {
        // check role logic
        require(checkRoles(orgId, msg.sender, role), "PassportContract: Unauthorised");

        for (uint i = 0; i < passportData.length; i++) {
            if (
                keccak256(bytes(passportData[i].passportId)) ==
                keccak256(bytes(""))
            ) {
                revert passportError({message: "Passport Id can not be null"});
            }
            passportRepo[passportData[i].passportId] = passportData[i];
            emit PassportEvent(passportData[i].dataHash, passportData[i].passportId, passportData[i].passportId, block.timestamp, passportData[i].schemaModel, passportData[i].version);
        }
    }

    /**
     * get passport data
     * @param passportId identifier
     */
    function getPassportData(string memory passportId) public view returns (Passport memory) {
        return passportRepo[passportId];
    }

    /**
     *  change owner address
     * @param newAdmin new owner address
     */
    function transferAdminRights(
        address newAdmin
    ) public ownerOnly notZeroAddress(newAdmin) {
        require(newAdmin != owner, "New admin cannot be current admin");
        owner = newAdmin;
        emit OwnershipTransfered(owner);
    }

    /**
     *  delete passport
     * @param passportId identifier
     *
     * @return Passport deleted passport
     */
    function removePassportData(
        string memory passportId
    ) public ownerOnly returns (Passport memory) {
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


    function blockRolesToOrgAddress(string memory orgId, address account, bytes32 [] memory roles) public onlyOwner{
        for (uint i = 0; i < roles.length; i++) {
            organisationBlackList[orgId][account][roles[i]]=true;
        }
    }
}