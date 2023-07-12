/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReportTemplate {
    struct Template {
        string templateId;
        string content;
    }

    mapping(string => Template) private templates;

    event TemplateAdded(string indexed templateId, string content);

    function addTemplate(string memory _templateId, string memory _content) public {
        require(bytes(_templateId).length > 0, "Template ID cannot be empty");
        require(bytes(_content).length > 0, "Template content cannot be empty");
      //  require(templates[_templateId].templateId == "", "Template with the same ID already exists");

        templates[_templateId] = Template(_templateId, _content);
        emit TemplateAdded(_templateId, _content);
    }

    function getTemplate(string memory _templateId) public view returns (string memory) {
        Template memory template = templates[_templateId];
        require(bytes(template.templateId).length > 0, "Template not found");

        return template.content;
    }
}

contract ReportTemplateUser {
    ReportTemplate private reportTemplateContract;

    constructor(address _reportTemplateContractAddress) {
        reportTemplateContract = ReportTemplate(_reportTemplateContractAddress);
    }

    function addTemplate(string memory _templateId, string memory _content) public {
        reportTemplateContract.addTemplate(_templateId, _content);
    }

    function getTemplate(string memory _templateId) public view returns (string memory) {
        return reportTemplateContract.getTemplate(_templateId);
    }
}