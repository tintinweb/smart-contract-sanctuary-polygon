// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.25 <0.9.0;

/** 
Assumptions
* Finanicial Institutions - Hospital
* Users - Customer
* Super Admin - Admin
*/

import "./Customers.sol";
import "./Hospitals.sol";

/**
 * @title KYC
 * @author Suresh Konakanchi
 * @dev Library for managing KYC process seemlessly using de-centralised system
 */
contract KYC is Customers, Hospitals {
    address admin;
    address[] internal userList;

    mapping(address => Types.User) internal users;
    mapping(string => Types.KycRequest) internal kycRequests;
    mapping(address => address[]) internal hospitalCustomers; // All customers associated to a Hospital
    mapping(address => address[]) internal customerhospitals; // All hospitals associated to a Customer

    /**
     * @notice Set admin to one who deploy this contract
     * Who will act as the super-admin to add all the financial institutions (hospitals)
     * @param name_ Name of the admin
     * @param email_ Email of the admin
     */
    constructor(string memory name_, string memory email_) {
        admin = 0xC860b36265CB42bCDC7c4EA21AC7c84e72B4A7D5;
        Types.User memory usr_ = Types.User({
            name: name_,
            email: email_,
            id_: admin,
            role: Types.Role.Admin,
            status: Types.HospitalStatus.Active
        });
        users[admin] = usr_;
        userList.push(admin);
    }

    // Modifiers

    /**
     * @notice Checks whether the requestor is admin
     */
    modifier isAdmin() {
        require(msg.sender == admin, "Only admin is allowed");
        _;
    }

    // Support functions

    /**
     * @notice Checks whether the KYC request already exists
     * @param reqId_ Unique Id of the KYC request
     * @return boolean which says request exists or not
     */
    function kycRequestExists(string memory reqId_)
        internal
        view
        returns (bool)
    {
        require(!Helpers.compareStrings(reqId_, ""), "Request Id empty");
        return Helpers.compareStrings(kycRequests[reqId_].id_, reqId_);
    }

    /**
     * @notice All kyc requests. Data will be sent in pages to avoid the more gas fee
     * @param pageNumber page number for which data is needed (1..2..3....n)
     * @param isForHospital List needed for hospital or for customer
     * @return totalPages Total pages available
     * @return KycRequest[] List of KYC requests in the current page
     */
    function getKYCRequests(uint256 pageNumber, bool isForHospital)
        internal
        view
        returns (uint256 totalPages, Types.KycRequest[] memory)
    {
        require(pageNumber > 0, "PN should be > zero");
        (
            uint256 pages,
            uint256 pageLength_,
            uint256 startIndex_,
            uint256 endIndex_
        ) = Helpers.getIndexes(
                pageNumber,
                isForHospital
                    ? hospitalCustomers[msg.sender]
                    : customerhospitals[msg.sender]
            );
        Types.KycRequest[] memory list_ = new Types.KycRequest[](pageLength_);
        for (uint256 i = startIndex_; i < endIndex_; i++)
            list_[i] = isForHospital
                ? kycRequests[
                    Helpers.append(msg.sender, hospitalCustomers[msg.sender][i])
                ]
                : kycRequests[
                    Helpers.append(customerhospitals[msg.sender][i], msg.sender)
                ];
        return (pages, list_);
    }

    // Events

    event KycRequestAdded(
        string reqId,
        string hospitalName,
        string customerName
    );
    event KycReRequested(
        string reqId,
        string hospitalName,
        string customerName
    );
    event KycStatusChanged(
        string reqId,
        address customerId,
        address hospitalId,
        Types.KycStatus status
    );
    event DataHashPermissionChanged(
        string reqId,
        address customerId,
        address hospitalId,
        Types.DataHashStatus status
    );

    // Admin Interface

    /**
     * @dev All the hospitals list. Data will be sent in pages to avoid the more gas fee
     * @param pageNumber page number for which data is needed (1..2..3....n)
     * @return totalPages Total pages available
     * @return Hospital[] List of hospitals in the current page
     */
    function getAllHospitals(uint256 pageNumber)
        public
        view
        isAdmin
        returns (uint256 totalPages, Types.Hospital[] memory)
    {
        return getallhospitals(pageNumber);
    }

    /**
     * @dev To add new hospital account
     * @param hospital_ Hospital details, which need to be added to the system
     */
    function addHospital(Types.Hospital memory hospital_) public isAdmin {
        addhospital(hospital_);
        // Adding to common list
        users[hospital_.id_] = Types.User({
            name: hospital_.name,
            email: hospital_.email,
            id_: hospital_.id_,
            role: Types.Role.Hospital,
            status: Types.HospitalStatus.Active
        });
        userList.push(hospital_.id_);
    }

    /**
     * @dev To add new hospital account
     * @param id_ Hospital's metamask address
     * @param email_ Hospital's email address that need to be updated
     * @param name_ Hospital's name which need to be updated
     */
    function updateHospitalDetails(
        address id_,
        string memory email_,
        string memory name_
    ) public isAdmin {
        updatehospital(id_, email_, name_);
        // Updating in common list
        users[id_].name = name_;
        users[id_].email = email_;
    }

    /**
     * @dev To add new hospital account
     * @param id_ Hospital's metamask address
     * @param makeActive_ If true, hospital will be marked as active, else, it will be marked as deactivateds
     */
    function activateDeactivateHospital(address id_, bool makeActive_)
        public
        isAdmin
    {
        // Updating in common list
        users[id_].status = activatedeactivatehospital(id_, makeActive_);
    }

    // Hospital Interface

    /**
     * @dev List of customers, who are linked to the current hospital. Data will be sent in pages to avoid the more gas fee
     * @param pageNumber page number for which data is needed (1..2..3....n)
     * @return totalPages Total pages available
     * @return KycRequest[] List of KYC requests in the current page
     */
    function getCustomersOfHospital(uint256 pageNumber)
        public
        view
        isValidHospital(msg.sender)
        returns (uint256 totalPages, Types.KycRequest[] memory)
    {
        return getKYCRequests(pageNumber, true);
    }

    /**
     * @notice Records new KYC request for a customer
     * @param customer_ Customer details for whom the request is to be raised
     * @param currentTime_ Current Date & Time in unix epoch timestamp
     * @param notes_ Any additional notes that need to be added
     */
    function addKycRequest(
        Types.Customer memory customer_,
        uint256 currentTime_,
        string memory notes_
    ) public isValidHospital(msg.sender) {
        string memory reqId_ = Helpers.append(msg.sender, customer_.id_);
        require(!kycRequestExists(reqId_), "User had kyc req.");

        kycRequests[reqId_] = Types.KycRequest({
            id_: reqId_,
            userId_: customer_.id_,
            customerName: customer_.name,
            hospitalId_: msg.sender,
            hospitalName: getsinglehospital(msg.sender).name,
            dataHash: customer_.dataHash,
            updatedOn: currentTime_,
            status: Types.KycStatus.Pending,
            dataRequest: Types.DataHashStatus.Pending,
            additionalNotes: notes_
        });
        hospitalCustomers[msg.sender].push(customer_.id_);
        customerhospitals[customer_.id_].push(msg.sender);
        emit KycRequestAdded(
            reqId_,
            kycRequests[reqId_].hospitalName,
            customer_.name
        );

        if (!customerExists(customer_.id_)) {
            addcustomer(customer_);
            // Adding to common list
            users[customer_.id_] = Types.User({
                name: customer_.name,
                email: customer_.email,
                id_: customer_.id_,
                role: Types.Role.Customer,
                status: Types.HospitalStatus.Active
            });
            userList.push(customer_.id_);
        }
    }

    /**
     * @notice Updates existing KYC request for a customer (It's a re-request)
     * @param id_ Customer ID for whom the request has to be re-raised
     * @param notes_ Any additional notes that need to be added
     */
    function reRequestForKycRequest(address id_, string memory notes_)
        public
        isValidHospital(msg.sender)
    {
        string memory reqId_ = Helpers.append(msg.sender, id_);
        require(kycRequestExists(reqId_), "KYC req not found");
        require(customerExists(id_), "User not found");

        // kycRequests[reqId_].status = Types.KycStatus.Pending;
        kycRequests[reqId_].dataRequest = Types.DataHashStatus.Pending;
        kycRequests[reqId_].additionalNotes = notes_;

        emit KycReRequested(
            reqId_,
            kycRequests[reqId_].hospitalName,
            kycRequests[reqId_].customerName
        );
    }

    /**
     * @dev To mark the KYC verification as failure
     * @param userId_ Id of the user
     * @param userId_ KYC Verified
     * @param note_ Any info that need to be shared
     */
    function updateKycVerification(
        address userId_,
        bool verified_,
        string memory note_
    ) public isValidHospital(msg.sender) {
        string memory reqId_ = Helpers.append(msg.sender, userId_);
        require(kycRequestExists(reqId_), "User doesn't have KYC req");

        Types.KycStatus status_ = Types.KycStatus.Pending;
        if (verified_) {
            status_ = Types.KycStatus.KYCVerified;
            updatekyccount(msg.sender);
            updatekycdoneby(userId_);
        } else {
            status_ = Types.KycStatus.KYCFailed;
        }

        kycRequests[reqId_].status = status_;
        kycRequests[reqId_].additionalNotes = note_;
        emit KycStatusChanged(reqId_, userId_, msg.sender, status_);
    }

    /**
     * @dev Search for customer details in the list that the hospital is directly linked to
     * @param id_ Customer's metamask Id
     * @return boolean to say if customer exists or not
     * @return Customer object to get the complete details of the customer
     * @return KycRequest object to get the details about the request & it's status
     * Costly operation if we had more customers linked to this single hospital
     */
    function searchCustomers(address id_)
        public
        view
        isValidCustomer(id_)
        isValidHospital(msg.sender)
        returns (
            bool,
            Types.Customer memory,
            Types.KycRequest memory
        )
    {
        bool found_;
        Types.Customer memory customer_;
        Types.KycRequest memory request_;
        (found_, customer_) = searchcustomers(
            id_,
            hospitalCustomers[msg.sender]
        );
        if (found_) request_ = kycRequests[Helpers.append(msg.sender, id_)];
        return (found_, customer_, request_);
    }

    // Customer Interface

    /**
     * @notice List of all hospitals. Data will be sent in pages to avoid the more gas fee
     * @dev This is customer facing RPC end point
     * @param pageNumber page number for which data is needed (1..2..3....n)
     * @return totalPages Total pages available
     * @return KycRequest[] List of KYC requests in the current page
     */
    function getHospitalRequests(uint256 pageNumber)
        public
        view
        isValidCustomer(msg.sender)
        returns (uint256 totalPages, Types.KycRequest[] memory)
    {
        return getKYCRequests(pageNumber, false);
    }

    /**
     * @dev Updates the KYC request (Either Approves or Rejects)
     * @param hospitalId_ Id of the hospital
     * @param approve_ Approve the data hash or reject
     * @param note_ Any info that need to be shared
     */
    function actionOnKycRequest(
        address hospitalId_,
        bool approve_,
        string memory note_
    ) public isValidCustomer(msg.sender) isValidHospital(hospitalId_) {
        string memory reqId_ = Helpers.append(hospitalId_, msg.sender);
        require(kycRequestExists(reqId_), "User doesn't have KYC req");

        Types.DataHashStatus status_ = Types.DataHashStatus.Pending;
        if (approve_) {
            status_ = Types.DataHashStatus.Approved;
        } else {
            status_ = Types.DataHashStatus.Rejected;
        }
        kycRequests[reqId_].dataRequest = status_;
        kycRequests[reqId_].additionalNotes = note_;

        emit DataHashPermissionChanged(
            reqId_,
            msg.sender,
            hospitalId_,
            status_
        );
    }

    /**
     * @dev Updates the user profile
     * @param name_ Customer name
     * @param email_ Email that need to be updated
     * @param mobile_ Mobile number that need to be updated
     */
    function updateProfile(
        string memory name_,
        string memory email_,
        uint256 mobile_
    ) public isValidCustomer(msg.sender) {
        updateprofile(name_, email_, mobile_);
        // Updating in common list
        users[msg.sender].name = name_;
        users[msg.sender].email = email_;
    }

    /**
     * @dev Updates the Datahash of the documents
     * @param hash_ Data hash value that need to be updated
     * @param currentTime_ Current Date Time in unix epoch timestamp
     */
    function updateDatahash(string memory hash_, uint256 currentTime_)
        public
        isValidCustomer(msg.sender)
    {
        updatedatahash(hash_, currentTime_);

        // Reset KYC verification status for all hospitals
        address[] memory hospitalsList_ = customerhospitals[msg.sender];
        for (uint256 i = 0; i < hospitalsList_.length; i++) {
            string memory reqId_ = Helpers.append(
                hospitalsList_[i],
                msg.sender
            );
            if (kycRequestExists(reqId_)) {
                kycRequests[reqId_].dataHash = hash_;
                kycRequests[reqId_].updatedOn = currentTime_;
                kycRequests[reqId_].status = Types.KycStatus.Pending;
                kycRequests[reqId_].additionalNotes = "Updated all my docs";
            }
        }
    }

    /**
     * @dev Removes the permission to a specific hospital, so that they can't access the documents again
     * @param hospitalId_ Id of the hospital to whom permission has to be revoked
     * @param notes_ Any additional notes that need to included
     */
    function removerDatahashPermission(
        address hospitalId_,
        string memory notes_
    ) public isValidCustomer(msg.sender) {
        string memory reqId_ = Helpers.append(hospitalId_, msg.sender);
        require(kycRequestExists(reqId_), "Permission not found");
        kycRequests[reqId_].dataRequest = Types.DataHashStatus.Rejected;
        kycRequests[reqId_].additionalNotes = notes_;
        emit DataHashPermissionChanged(
            reqId_,
            msg.sender,
            hospitalId_,
            Types.DataHashStatus.Rejected
        );
    }

    /**
     * @dev Search for hospital details in the list that the customer is directly linked to
     * @param hospitalId_ Hospital's metamask Id
     * @return boolean to say if hospital exists or not
     * @return Hospital object to get the complete details of the hospital
     * @return KycRequest object to get the details about the request & it's status
     * Costly operation if we had more hospitals linked to this single customer
     */
    function searchHospitals(address hospitalId_)
        public
        view
        isValidCustomer(msg.sender)
        isValidHospital(hospitalId_)
        returns (
            bool,
            Types.Hospital memory,
            Types.KycRequest memory
        )
    {
        bool found_;
        Types.Hospital memory hospital_;
        Types.KycRequest memory request_;
        address[] memory hospitals_ = customerhospitals[msg.sender];

        for (uint256 i = 0; i < hospitals_.length; i++) {
            if (hospitals_[i] == hospitalId_) {
                found_ = true;
                hospital_ = getsinglehospital(hospitalId_);
                request_ = kycRequests[Helpers.append(hospitalId_, msg.sender)];
                break;
            }
        }
        return (found_, hospital_, request_);
    }

    // Common Interface

    /**
     * @dev Updates the KYC request (Either Approves or Rejects)
     * @return User object which contains the role & other basic info
     */
    function whoAmI() public view returns (Types.User memory) {
        require(msg.sender != address(0), "Sender Id Empty");
        require(users[msg.sender].id_ != address(0), "User Id Empty");
        return users[msg.sender];
    }

    /**
     * @dev To get details of the customer
     * @param id_ Customer's metamask address
     * @return Customer object which will have complete details of the customer
     */
    function getCustomerDetails(address id_)
        public
        view
        isValidCustomer(id_)
        returns (Types.Customer memory)
    {
        return getcustomerdetails(id_);
    }

    /**
     * @dev To get details of the hospital
     * @param id_ Hospital's metamask address
     * @return Hospital object which will have complete details of the hospital
     */
    function getHospitalDetails(address id_)
        public
        view
        isValidHospital(id_)
        returns (Types.Hospital memory)
    {
        return getsinglehospital(id_);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.25 <0.9.0;

import "./Types.sol";
import "./Helpers.sol";

/**
 * @title Customers
 * @author Suresh Konakanchi
 * @dev Library for managing all customers, who are involved in the KYC process
 */
contract Customers {
    address[] internal customerList;
    mapping(address => Types.Customer) internal customers;

    // Events

    event CustomerAdded(address id_, string name, string email);
    event CustomerDataUpdated(address id_, string name, string email);
    event DataHashUpdated(address id_, string customerName, string dataHash);

    // Modifiers

    /**
     * @notice Checks whether customer already exists
     * @param id_ Metamask address of the customer
     */
    modifier isValidCustomer(address id_) {
        require(id_ != address(0), "Id is Empty");
        require(customers[id_].id_ != address(0), "User Id Empty");
        require(
            !Helpers.compareStrings(customers[id_].email, ""),
            "User Email Empty"
        );
        _;
    }

    // Support Functions

    /**
     * @notice Checks whether customer already exists
     * @param id_ Metamask address of the customer
     * @return exists_ boolean value to say if customer exists or not
     */
    function customerExists(address id_) internal view returns (bool exists_) {
        require(id_ != address(0), "Id is empty");
        if (
            customers[id_].id_ != address(0) &&
            !Helpers.compareStrings(customers[id_].email, "")
        ) {
            exists_ = true;
        }
    }

    // Contract Functions

    /**
     * @dev To get details of the customer
     * @param id_ Customer's metamask address
     * @return Customer object which will have complete details of the customer
     */
    function getcustomerdetails(address id_)
        internal
        view
        returns (Types.Customer memory)
    {
        return customers[id_];
    }

    /**
     * @dev Updates the user profile
     * @param name_ Customer name
     * @param email_ Email that need to be updated
     * @param mobile_ Mobile number that need to be updated
     */
    function updateprofile(
        string memory name_,
        string memory email_,
        uint256 mobile_
    ) internal {
        customers[msg.sender].name = name_;
        customers[msg.sender].email = email_;
        customers[msg.sender].mobileNumber = mobile_;
        emit CustomerDataUpdated(msg.sender, name_, email_);
    }

    /**
     * @dev Add new customer
     * @param customer_ Customer object
     */
    function addcustomer(Types.Customer memory customer_) internal {
        customers[customer_.id_] = customer_;
        customerList.push(customer_.id_);
        emit CustomerAdded(customer_.id_, customer_.name, customer_.email);
    }

    /**
     * @dev To Update KYC verification hospital
     * @param id_ Customer's metamask ID
     */
    function updatekycdoneby(address id_) internal {
        require(id_ != address(0), "Customer Id Empty");
        customers[id_].kycVerifiedBy = msg.sender;
    }

    /**
     * @dev Updates the Datahash of the documents
     * @param hash_ Data hash value that need to be updated
     * @param currentTime_ Current Date Time in unix epoch timestamp
     */
    function updatedatahash(string memory hash_, uint256 currentTime_)
        internal
    {
        customers[msg.sender].dataHash = hash_;
        customers[msg.sender].dataUpdatedOn = currentTime_;
        emit DataHashUpdated(msg.sender, customers[msg.sender].name, hash_);
    }

    /**
     * @dev Search for customer details in the list that the hospital is directly linked to
     * @param id_ Customer's metamask Id
     * @param customers_ Customer metamask Id's
     * @return boolean to say if customer exists or not
     * @return Customer object to get the complete details of the customer
     * Costly operation if we had more customers linked to this single hospital
     */
    function searchcustomers(address id_, address[] memory customers_)
        internal
        view
        returns (bool, Types.Customer memory)
    {
        bool found_;
        Types.Customer memory customer_;

        for (uint256 i = 0; i < customers_.length; i++) {
            if (customers_[i] == id_) {
                found_ = true;
                customer_ = customers[id_];
                break;
            }
        }
        return (found_, customer_);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.25 <0.9.0;

import "./Types.sol";
import "./Helpers.sol";

/**
 * @title Hospitals
 * @author Suresh Konakanchi
 * @dev Library for managing all finanicial institutions thata were involved in the KYC process
 */

contract Hospitals {
    address[] internal hospitalList;
    mapping(address => Types.Hospital) internal hospitals;

    // Events

    event HospitalAdded(
        address id_,
        string name,
        string email,
        string ifscCode
    );
    event HospitalUpdated(address id_, string name, string email);
    event HospitalActivated(address id_, string name);
    event HospitalDeactivated(address id_, string name);

    // Modifiers

    /**
     * @notice Checks whether the requestor is hospital & is active
     * @param id_ Metamask address of the hospital
     */
    modifier isValidHospital(address id_) {
        require(hospitals[id_].id_ != address(0), "Hospital not found");
        require(hospitals[id_].id_ == id_, "Hospital not found");
        require(
            hospitals[id_].status == Types.HospitalStatus.Active,
            "Hospital is not active"
        );
        _;
    }

    // Contract Methods

    /**
     * @dev All the hospitals list. Data will be sent in pages to avoid the more gas fee
     * @param pageNumber page number for which data is needed (1..2..3....n)
     * @return totalPages Total pages available
     * @return Hospital[] List of hospitals in the current page
     */
    function getallhospitals(uint256 pageNumber)
        internal
        view
        returns (uint256 totalPages, Types.Hospital[] memory)
    {
        require(pageNumber > 0, "PN should be > 0");
        (
            uint256 pages,
            uint256 pageLength_,
            uint256 startIndex_,
            uint256 endIndex_
        ) = Helpers.getIndexes(pageNumber, hospitalList);

        Types.Hospital[] memory hospitalsList_ = new Types.Hospital[](
            pageLength_
        );
        for (uint256 i = startIndex_; i < endIndex_; i++)
            hospitalsList_[i] = hospitals[hospitalList[i]];
        return (pages, hospitalsList_);
    }

    /**
     * @dev To get details of the single hospital
     * @param id_ metamask address of the requested hospital
     * @return Hospital Details of the hospital
     */
    function getsinglehospital(address id_)
        internal
        view
        returns (Types.Hospital memory)
    {
        require(id_ != address(0), "Hospital Id Empty");
        return hospitals[id_];
    }

    /**
     * @dev To add new hospital account
     * @param hospital_ Hospital details, which need to be added to the system
     */
    function addhospital(Types.Hospital memory hospital_) internal {
        require(hospitals[hospital_.id_].id_ == address(0), "Hospital exists");

        hospitals[hospital_.id_] = hospital_;
        hospitalList.push(hospital_.id_);
        emit HospitalAdded(
            hospital_.id_,
            hospital_.name,
            hospital_.email,
            hospital_.ifscCode
        );
    }

    /**
     * @dev To add new hospital account
     * @param id_ Hospital's metamask address
     * @param email_ Hospital's email address that need to be updated
     * @param name_ Hospital's name which need to be updated
     */
    function updatehospital(
        address id_,
        string memory email_,
        string memory name_
    ) internal {
        require(hospitals[id_].id_ != address(0), "Hospital not found");

        hospitals[id_].name = name_;
        hospitals[id_].email = email_;
        emit HospitalUpdated(id_, name_, email_);
    }

    /**
     * @dev To add new hospital account
     * @param id_ Hospital's metamask address
     * @param makeActive_ If true, hospital will be marked as active, else, it will be marked as deactivateds
     * @return HospitalStatus current status of the hospital to update in common list
     */
    function activatedeactivatehospital(address id_, bool makeActive_)
        internal
        returns (Types.HospitalStatus)
    {
        require(hospitals[id_].id_ != address(0), "Hospital not found");

        if (
            makeActive_ &&
            hospitals[id_].status == Types.HospitalStatus.Inactive
        ) {
            hospitals[id_].status = Types.HospitalStatus.Active;
            emit HospitalActivated(id_, hospitals[id_].name);

            // Updating in common list
            return Types.HospitalStatus.Active;
        } else if (
            !makeActive_ && hospitals[id_].status == Types.HospitalStatus.Active
        ) {
            hospitals[id_].status = Types.HospitalStatus.Inactive;
            emit HospitalDeactivated(id_, hospitals[id_].name);

            // Updating in common list
            return Types.HospitalStatus.Inactive;
        } else {
            // Already upto date
            return hospitals[id_].status;
        }
    }

    /**
     * @dev To update the kyc count that hospital did
     * @param id_ Hospital's metamask address
     */
    function updatekyccount(address id_) internal {
        require(id_ != address(0), "Hospital not found");
        hospitals[id_].kycCount++;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.25 <0.9.0;

/**
 * @title Types
 * @author Suresh Konakanchi
 * @dev Library for managing all custom types that were used in KYC process
 */

library Types {
    enum Role {
        Admin, // 0
        Hospital, // 1
        Customer // 2
    }

    enum HospitalStatus {
        Active, // 0
        Inactive // 1
    }

    enum KycStatus {
        Pending, // 0
        KYCVerified, // 1
        KYCFailed // 2
    }

    enum DataHashStatus {
        Pending, // 0
        Approved, // 1
        Rejected // 2
    }

    struct User {
        string name;
        string email;
        address id_;
        Role role;
        HospitalStatus status;
    }

    struct Customer {
        string name;
        string email;
        uint256 mobileNumber;
        address id_;
        address kycVerifiedBy; // Address of the hospital only if KYC gets verified
        string dataHash; // Documents will be stored in decentralised storage & a hash will be created for the same
        uint256 dataUpdatedOn;
    }

    struct Hospital {
        string name;
        string email;
        address id_;
        string ifscCode;
        uint16 kycCount; // How many KCY's did this hospital completed so far
        HospitalStatus status; // RBI, we call "admin" here can disable the hospital at any instance
    }

    struct KycRequest {
        string id_; // Combination of customer Id & hospital is going to be unique
        address userId_;
        string customerName;
        address hospitalId_;
        string hospitalName;
        string dataHash;
        uint256 updatedOn;
        KycStatus status;
        DataHashStatus dataRequest; // Get approval from user to access the data
        string additionalNotes; // Notes that can be added if KYC verification fails  OR
        // if customer rejects the access & hospital wants to re-request with some message
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.25 <0.9.0;

/**
 * @title Helpers
 * @author Suresh Konakanchi
 * @dev Library for managing all the helper functions
 */
library Helpers {
    /**
     * @dev List of customers, who are linked to the current hospital. Data will be sent in pages to avoid the more gas fee
     * @param pageNumber page number for which data is needed (1..2..3....n)
     * @param users_ User Id's who are linked to the requested hospital
     * @return pages Total pages available
     * @return pageLength_ Length of the current page
     * @return startIndex_ Starting index of the current page
     * @return endIndex_ Ending index of the current page
     */
    function getIndexes(uint256 pageNumber, address[] memory users_)
        internal
        pure
        returns (
            uint256 pages,
            uint256 pageLength_,
            uint256 startIndex_,
            uint256 endIndex_
        )
    {
        uint256 reminder_ = users_.length % 25;
        pages = users_.length / 25;
        if (reminder_ > 0) pages++;

        pageLength_ = 25;
        startIndex_ = 25 * (pageNumber - 1);
        endIndex_ = 25 * pageNumber;

        if (pageNumber > pages) {
            // Page requested is not existing
            pageLength_ = 0;
            endIndex_ = 0;
        } else if (pageNumber == pages && reminder_ > 0) {
            // Last page where we don't had 25 records
            pageLength_ = reminder_;
            endIndex_ = users_.length;
        }
    }

    /**
     * @notice Internal function which doesn't alter any stage or read any data
     * Used to compare the string operations. Little costly in terms of gas fee
     * @param a string-1 that is to be compared
     * @param b string-2 that is to be compared
     * @return boolean value to say if both strings matched or not
     */
    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    /**
     * @notice Internal function used to concatenate two addresses.
     * @param a address-1
     * @param b address-2 that needs to be appended
     * @return string value after concatenating
     */
    function append(address a, address b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }
}