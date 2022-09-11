// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.11;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract PackageManager {
    struct Package {
        address owner;
        string defaultVersion;
        mapping(string => string) versionToDataHash;
    }

    event PackageCreated(address owner, string pkgName);
    event PackageVersionCreated(
        string pkgName,
        string versionName,
        string dataHash,
        bool changeDefaultVersion
    );

    event DefaultVersionChanged(string pkgName, string versionName);

    mapping(string => Package) public nameToPackage;

    modifier onlyPackageOwner(string memory packageName) {
        address packageOwner = nameToPackage[packageName].owner;
        require(msg.sender == packageOwner, "sender is not owner of package");
        _;
    }

    modifier onlyPackageNotExist(string memory packageName) {
        address packageOwner = nameToPackage[packageName].owner;
        require(address(0) == packageOwner, "package already exist");
        _;
    }

    modifier onlyVersionExist(
        string memory packageName,
        string memory version
    ) {
        string memory dataHash = nameToPackage[packageName].versionToDataHash[
            version
        ];
        require(bytes(dataHash).length > 0, "version does not exist");
        _;
    }

    modifier onlyVersionNotExist(
        string memory packageName,
        string memory version
    ) {
        string memory dataHash = nameToPackage[packageName].versionToDataHash[
            version
        ];
        require(bytes(dataHash).length == 0, "version already exist");
        _;
    }

    function getRelease(string memory pkgName, string memory pkgVersion)
        public
        view
        onlyVersionExist(pkgName, pkgVersion)
        returns (string memory)
    {
        return nameToPackage[pkgName].versionToDataHash[pkgVersion];
    }

    function createPackage(string memory packageName)
        public
        onlyPackageNotExist(packageName)
    {
        require(
            bytes(packageName).length != 0,
            "package name cannot be empty string"
        );
        nameToPackage[packageName].owner = msg.sender;
        emit PackageCreated(msg.sender, packageName);
    }

    function releaseNewVersion(
        string memory packageName,
        string memory versionName,
        string memory dataHash,
        bool isDefault
    )
        public
        onlyPackageOwner(packageName)
        onlyVersionNotExist(packageName, versionName)
    {
        require(
            bytes(dataHash).length != 0,
            "data hash cannot be empty string"
        );

        require(
            bytes(versionName).length != 0,
            "version cannot be empty string"
        );
        nameToPackage[packageName].versionToDataHash[versionName] = dataHash;
        bool changeDefaultVersion = isDefault ||
            bytes(nameToPackage[packageName].defaultVersion).length == 0;
        if (changeDefaultVersion) {
            nameToPackage[packageName].defaultVersion = versionName;
        }
        emit PackageVersionCreated(
            packageName,
            versionName,
            dataHash,
            changeDefaultVersion
        );
    }

    function setDefaultVersion(
        string memory packageName,
        string memory versionName
    )
        public
        onlyPackageOwner(packageName)
        onlyVersionExist(packageName, versionName)
    {
        nameToPackage[packageName].defaultVersion = versionName;
        emit DefaultVersionChanged(packageName, versionName);
    }
}