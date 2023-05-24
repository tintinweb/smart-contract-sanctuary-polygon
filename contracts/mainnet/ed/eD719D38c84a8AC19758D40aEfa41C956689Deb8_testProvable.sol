// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface OracleAddrResolverI {
    function getAddress() external returns (address _address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ProvableI {
    function setProofType(bytes1 _proofType) external;

    function setCustomGasPrice(uint _gasPrice) external;

    function cbAddress() external returns (address _cbAddress);

    function randomDS_getSessionPubKeyHash()
        external
        view
        returns (bytes32 _sessionKeyHash);

    function getPrice(
        string calldata _datasource
    ) external returns (uint _dsprice);

    function getPrice(
        string calldata _datasource,
        uint _gasLimit
    ) external returns (uint _dsprice);

    function queryN(
        uint _timestamp,
        string calldata _datasource,
        bytes calldata _argN
    ) external payable returns (bytes32 _id);

    function query(
        uint _timestamp,
        string calldata _datasource,
        string calldata _arg
    ) external payable returns (bytes32 _id);

    function query2(
        uint _timestamp,
        string calldata _datasource,
        string calldata _arg1,
        string calldata _arg2
    ) external payable returns (bytes32 _id);

    function query_withGasLimit(
        uint _timestamp,
        string calldata _datasource,
        string calldata _arg,
        uint _gasLimit
    ) external payable returns (bytes32 _id);

    function queryN_withGasLimit(
        uint _timestamp,
        string calldata _datasource,
        bytes calldata _argN,
        uint _gasLimit
    ) external payable returns (bytes32 _id);

    function query2_withGasLimit(
        uint _timestamp,
        string calldata _datasource,
        string calldata _arg1,
        string calldata _arg2,
        uint _gasLimit
    ) external payable returns (bytes32 _id);
}

// SPDX-License-Identifier: MIT
//0xEC681fB03157C67Cd877Db6Fd27Ce301c92c5D09
pragma solidity 0.8.17; // to check

import "./Provable/interfaces/provable-interface.sol";
import "./Provable/interfaces/provable-address-resolver-interface.sol";

contract testProvable  {
  ProvableI provable;
    OracleAddrResolverI OAR;
    uint provable_network_name;



  function getCodeSize(address _addr) internal view returns (uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function test() public returns(uint) {
      if (provable_network_name ==7){
    
      provable = ProvableI(OAR.getAddress());
      return (provable.getPrice("URL"));
      } else return provable_network_name;
    }

    function getaddress() public returns(address) {
        return OAR.getAddress();
    }

    function getnetwork() public view returns(uint) {
        return provable_network_name;
    }

     constructor()  {
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed) > 0) {
            //mainnet
            OAR = OracleAddrResolverI(
                0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed
            );
            provable_network_name=1;
            return;
            //return("eth_mainnet");
            
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1) > 0) {
            //ropsten testnet
            OAR = OracleAddrResolverI(
                0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1
            );
            provable_network_name=2;
           // return("eth_ropsten3");
            return;
            
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e) > 0) {
            //kovan testnet
            OAR = OracleAddrResolverI(
                0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e
            );
            provable_network_name=3;
             return;
           // return("eth_kovan");
            
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48) > 0) {
            //rinkeby testnet
            OAR = OracleAddrResolverI(
                0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48
            );
            provable_network_name=4;
             return;
            //return("eth_rinkeby");
            
        }
        if (getCodeSize(0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41) > 0) {
            //goerli testnet
            OAR = OracleAddrResolverI(
                0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41
            );
            provable_network_name=5;
             return;
            //return("eth_goerli");
            
        }
        if (getCodeSize(0x90A0F94702c9630036FB9846B52bf31A1C991a84) > 0) {
            //bsc mainnet
            OAR = OracleAddrResolverI(
                0x90A0F94702c9630036FB9846B52bf31A1C991a84
            );
            provable_network_name=6;
             return;
            //return("bsc_mainnet");
            
        }
        if (getCodeSize(0x816ec2AF1b56183F82f8C05759E99FEc3c3De609) > 0) {
            //polygon mainnet
            OAR = OracleAddrResolverI(
                0x816ec2AF1b56183F82f8C05759E99FEc3c3De609
            );
            provable_network_name=7;
             return;
           // return("polygon_mainnet");
            
        }
        if (getCodeSize(0x14B31A1C66a9f3D18DFaC2d123FE8cE5847b7F85) > 0) {
            //sepolia mainnet
            OAR = OracleAddrResolverI(
                0x14B31A1C66a9f3D18DFaC2d123FE8cE5847b7F85
            );
            provable_network_name=8;
             return;
           // return("sepolia_mainnet");
            
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475) > 0) {
            //ethereum-bridge
            OAR = OracleAddrResolverI(
                0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475
            );
            provable_network_name=9;
             return;
           // return("ethereum-bridge");
            
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF) > 0) {
            //ether.camp ide
            OAR = OracleAddrResolverI(
                0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF
            );
            provable_network_name=10;
             return;
            //return("ether.camp ide");
            
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA) > 0) {
            //browser-solidity
            OAR = OracleAddrResolverI(
                0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA
            );
            provable_network_name=11;
             return;
           // return("browser-solidity");
            
        }
        provable_network_name=12;
       // return "nothing";
    }

}