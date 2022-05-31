/**
 *Submitted for verification at polygonscan.com on 2022-05-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

contract Storage {

    event certificateIssued(string issuer, string certificateID);

    mapping(string => string) certifiacte;

    function newCertificateM1(string memory certificateID) public {
    }

    function newCertificateM2(string memory certificateID) public {
        emit certificateIssued("DUK", certificateID);
    }

    function newCertificateM3(string memory batch,string memory certificateID) public {
        certifiacte[batch] = certificateID;
    }

    function newCertificateM4(string memory batch,string memory certificateID) public {
        certifiacte[batch] = certificateID;
        emit certificateIssued("DUK", certificateID);
    }

    //admin privilage codes ---here---
}