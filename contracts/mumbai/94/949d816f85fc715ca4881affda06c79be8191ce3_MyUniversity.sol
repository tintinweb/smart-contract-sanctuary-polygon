/**
 *Submitted for verification at polygonscan.com on 2023-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface University {
    function introduction() external view returns (string memory);
    function accreditation() external view returns (string memory);
    function qualifiedFaculty() external view returns (string memory);
    function comprehensiveCurriculum() external view returns (string memory);
    function adequateResources() external view returns (string memory);
    function researchOpportunities() external view returns (string memory);
    function campusFacilities() external view returns (string memory);
    function studentSupportServices() external view returns (string memory);
    function internshipAndJobPlacementOpportunities() external view returns (string memory);
    function strongAlumniNetwork() external view returns (string memory);
    function commitmentToDiversityAndInclusion() external view returns (string memory);
}

contract MyUniversity is University {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function introduction() external pure override returns (string memory) {
        return "Welcome to our prestigious institution renowned for its commitment to academic excellence, innovation, and fostering the next generation of leaders and scholars. We are proud to be one of the world's top research-intensive universities, driven to invent and innovate. Our students have the opportunity to learn from and work with preeminent thought leaders through our multidisciplinary network of teaching and research faculty, alumni, and partners. The ideas, innovations, and actions of more than 560,000 graduates continue to have a positive impact on the world. Our core academic mission is to educate global citizens who will thrive in society and shape our world. We are a global leader in translating knowledge to impact and are a catalyst for addressing global challenges through interdisciplinary teaching and research. We take pride in our history of innovation and our entrepreneurial spirit. We are inspired by our world-renowned researchers who are always pushing the boundaries of knowledge. We are committed to excellence and equity in everything we do. We strive to be a model of diversity, inclusion, and openness. We educate students to become global citizens, critical thinkers, and agents of change. We embrace our responsibility to the communities we serve and the world we live in. We are a university for the world. We are a university for the future. We are a university for you. We are a university for the world. We are a university for the future.";
    }

    function accreditation() external pure override returns (string memory) {
        return "This university is accredited by the Accreditation Council for Business Schools and Programs (ACBSP). ACBSP is a leading specialized accreditation body for business education supporting, celebrating, and rewarding teaching excellence. The association embraces the virtues of teaching excellence and emphasizes to students that it is essential to learn. ACBSP acknowledges the importance of scholarly research and inquiry and believes that such activities facilitate improved teaching. Institutions are strongly encouraged to pursue a reasonable mutually beneficial balance between teaching and research. And further, ACBSP encourages faculty involvement within the contemporary business world to enhance the quality of classroom instruction and to contribute to student learning.";
    }

    function qualifiedFaculty() external pure override returns (string memory) {
        return "Our faculty members are highly qualified and experienced. The faculty members have the necessary academic credentials, expertise, and teaching experience in their respective fields.";
    }

    function comprehensiveCurriculum() external pure override returns (string memory) {
        return "We offer a wide range of academic programs and disciplines to cater to diverse student interests and career goals. The curriculum is up-to-date, relevant, and aligned with industry standards, providing students with a solid foundation of knowledge and skills.";
    }

    function adequateResources() external pure override returns (string memory) {
        return "We have sufficient resources to support teaching, learning, and research activities. This includes well-equipped classrooms, laboratories, libraries, and access to technology and online resources. Additionally, we provide support services like academic advising, career counseling, and student organizations.";
    }

    function researchOpportunities() external pure override returns (string memory) {
        return "We foster a culture of research and scholarly activity. We provide opportunities for faculty and students to engage in research projects, collaborate with peers and professionals, and contribute to advancements in knowledge.";
    }

    function campusFacilities() external pure override returns (string memory) {
        return "We have adequate infrastructure and facilities to support a conducive learning environment. This includes classrooms, lecture halls, computer labs, research facilities, libraries, student centers, recreational areas, and sports facilities.";
    }

    function studentSupportServices() external pure override returns (string memory) {
        return "We offer various support services to assist students in their academic and personal development. These may include tutoring programs, counseling services, career services, disability support, and cultural and diversity initiatives.";
    }

    function internshipAndJobPlacementOpportunities() external pure override returns (string memory) {
        return "We have strong connections with industries and employers, providing students with opportunities for internships, cooperative education programs, and job placements. This helps students gain practical experience and enhances their employability after graduation.";
    }

    function strongAlumniNetwork() external pure override returns (string memory) {
        return "We have an active and engaged alumni network that can provide valuable support to students and enhance their post-graduation prospects. We cultivate relationships with alumni, organizing networking events, mentorship programs, and career fairs.";
    }

    function commitmentToDiversityAndInclusion() external pure override returns (string memory) {
        return "We are committed to promoting diversity, inclusivity, and equal opportunities for all students and staff. We foster a welcoming and respectful environment that celebrates differences and provides support for underrepresented groups.";
    }
}