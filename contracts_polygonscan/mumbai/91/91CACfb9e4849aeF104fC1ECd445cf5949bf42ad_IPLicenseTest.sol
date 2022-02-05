/**
 *Submitted for verification at polygonscan.com on 2022-02-04
*/

// File: contracts/IIPLicense.sol



pragma solidity ^0.8.7;

interface IIPLicense {
    function getLicense(
        address _address, 
        string memory _creator,
        string memory _email,
        uint256 _exclusive,
        uint256 _limit
        ) external view returns (string memory);
    function getLicense(
        string memory  _address, 
        string memory _creator,
        string memory _email,
        uint256 _exclusive,
        uint256 _limit
        ) external view returns (string memory);
}
// File: contracts/IPLicenseTest.sol


pragma solidity ^0.8.7;


contract IPLicenseTest {
    function getLicense() public view returns (string memory) {
        address _address = 0x166914f6Ffbd1e2453c07DAE311c9d9aC05c989f;
        return IIPLicense(_address).getLicense(address(this), 'KaizenSailor', '[email protected]', 1, 100000);
    }
}