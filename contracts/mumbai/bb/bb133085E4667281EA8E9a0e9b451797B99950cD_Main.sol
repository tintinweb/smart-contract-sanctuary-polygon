pragma solidity ^0.8.9;

contract Main {
    // a structure for file metadata
    struct DocInfo {
        string ipfsHash;
        string fileName;
        string fileType;
        uint256 fileSize;
        string dateAdded;
        string timeAdded;
        uint256 downloadCount;
        string PUF;
    }

    // user info structure for sign up
    struct UserInfo {
        string name;
        string username;
        string email;
        bool isexist;
    }

    DocInfo[] private metadata;
    // storing metadata of uploaded files

    mapping(string => UserInfo) userNameToData;
    // user Address to UserInfo

    string[] private adminList;
    //list of all admin addresses

    mapping(string => string[]) downloadedByUser;
    // mapping user address by ipfs code of downloaded files

    mapping(string => string[]) uploadedByAdmin;

    // mapping admin address by ipfs code of uploaded files

    constructor() {
        adminList.push("0x39ee928476d24c200528118579d6d16ca011DA08");
        // first admin only who can add another admins
    }

    modifier validAdmin(string memory prev, string memory newAdmin) {
        uint8 flag = 0;

        for (uint256 i = 0; i < adminList.length; i++) {
            if (
                keccak256(abi.encodePacked(adminList[i])) ==
                keccak256(abi.encodePacked(prev))
            ) {
                flag = 1;
            }

            if (
                keccak256(abi.encodePacked(adminList[i])) ==
                keccak256(abi.encodePacked(newAdmin))
            ) {
                flag = 2;
                // new admin already in admin list
                break;
            }
        }

        require(flag == 1, "This User can't be a Admin");
        _;
    }

    modifier isSignUp(string memory _address) {
        require(
            userNameToData[_address].isexist != true,
            "You are Already signIn.."
        );
        _;
    }

    // before adding a new admin check 2 things:
    // 1) new user is not in admin list
    // 2) prev. user is in admin list
    function adminAdd(
        string memory prev,
        string memory newAdmin
    ) public validAdmin(prev, newAdmin) {
        adminList.push(newAdmin);
    }

    //  new user sign Up but before sign Up check:
    //  already this user is register or not
    function signUp(
        string memory _address,
        string memory _name,
        string memory _userName,
        string memory _email
    ) public isSignUp(_address) {
        UserInfo memory userInfo = UserInfo(_name, _userName, _email, true);

        userNameToData[_address] = userInfo;
    }

    // just check already registerd or not
    function signIn(string memory _address) public view returns (UserInfo memory) {
        return userNameToData[_address];
    }

    //  checkin for valid admin
    function isAdmin(string memory _address) public view returns (bool) {
        bool flag = false;

        for (uint256 i = 0; i < adminList.length; i++) {
            if (
                keccak256(abi.encodePacked(adminList[i])) ==
                keccak256(abi.encodePacked(_address))
            ) {
                flag = true;
                break;
            }
        }

        return flag;
    }

    // adding new file in system
    function addFile(
        string memory _address,
        string memory _ipfsHash,
        string memory _fileName,
        string memory _fileType,
        string memory _dateAdded,
        string memory _timeAdded,
        uint256 _fileSize,
        string memory _PUF
    ) public {
        DocInfo memory docInfo = DocInfo(
            _ipfsHash,
            _fileName,
            _fileType,
            _fileSize,
            _dateAdded,
            _timeAdded,
            0,
            _PUF
        );

        metadata.push(docInfo);
        newUploadByAdmin(_address, _ipfsHash);
    }

    // if a new file is downloaded by user then increase download count of file and added the file in download list of user
    function newDownloadByUser(
        string memory _address,
        string memory _ipfs
    ) public {
        downloadedByUser[_address].push(_ipfs);

        newDownload(_ipfs);
    }

    // if a new file is uploaded then added this file to list of files for admin
    function newUploadByAdmin(
        string memory _address,
        string memory _ipfs
    ) private {
        uploadedByAdmin[_address].push(_ipfs);
    }

    function newDownload(string memory _ipfsHash) private {
        for (uint16 i = 0; i < metadata.length; i++) {
            if (
                keccak256(abi.encodePacked(metadata[i].ipfsHash)) ==
                keccak256(abi.encodePacked(_ipfsHash))
            ) {
                metadata[i].downloadCount += 1;
            }
        }
    }

    // return all available files
    function getFiles() public view returns (DocInfo[] memory) {
        return metadata;
    }

    // return all files downloaded by a user
    function downloadedbyUser(
        string memory _address
    ) public view returns (string[] memory) {
        return downloadedByUser[_address];
    }

    // return all files uploaded by a admin
    function uploadedbyAdmin(
        string memory _address
    ) public view returns (string[] memory) {
        return uploadedByAdmin[_address];
    }
}