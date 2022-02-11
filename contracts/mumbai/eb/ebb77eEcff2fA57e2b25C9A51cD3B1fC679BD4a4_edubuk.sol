/**
 *Submitted for verification at polygonscan.com on 2022-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// employeeid and company id is a unique natural number representing a account globally.
contract edubuk {
    company[] public companies;
    institute[] public institutes;
    employee[] public employees;
    student[] public students;
    expert[] public experts;
    learner[] public learners;
    certificate[] public certifications;
    miitprofile[] public miitprofiles;
    clp[] public clps;
    grade[] public grades;
    endorsment[] public endorsments;
    skill[] public skills;
    internship[] public internships;
    project[] public projects;
    experience[] public experiences;

// mapping of account's mail id with account's wallet address
// mapping(string => address) public email_to_address;
// mapping of wallet address with account id
mapping(address => uint256) public address_to_id;
// mapping of wallet address with bool representing account status (Company/employee)
mapping(address => bool) public is_company; 
// mapping of wallet address with bool representing account status (institute/Student)
mapping(address => bool) public is_institute;
// mapping of wallet address with bool representing account status (expert/Learner)
mapping(address => bool) public is_expert;

mapping(address => employee) private all_employees;

function getEmployeeData (address _employee) external view returns (employee memory abc){

    return all_employees [_employee];
}


//Function Modifiers (only the linked Employee should be able to call them.)
modifier verifiedEmployee(uint256 employee_id) {
    require(employee_id == address_to_id[msg.sender]);
    _;
}

//Function Modifiers (only the linked Student should be able to call them.)
modifier verifiedStudent(uint256 student_id) {
    require(student_id == address_to_id[msg.sender]);
    _;
}

//Function Modifiers (only the linked Learner should be able to call them.)
modifier verifiedLearner(uint256 learner_id) {
    require(learner_id == address_to_id[msg.sender]);
    _;
}    

//ACCOUNT STRUCTURE

//COMPANY ACCOUNT
struct company {
    uint256 id; //company id which is the index of id in the global company array
    uint256 employee_id;
    string name;
    address wallet_address;
    uint256[] current_employees;
    uint256[] previous_employees;
    uint256[] requested_employees;
}

struct institute {
    uint256 id; //Institute id which is the index of id in the global Institute array
    string name;
    address wallet_address;
    bool is_dean;
    uint256[] current_students;
    uint256[] previous_students;
    uint256[] requested_students;
}

struct expert {
    uint256 id; //Expert id which is the index of id in the global Expert array
    string name;
    address wallet_address;
    bool is_expertadmin;
    uint256[] current_learners;
    uint256[] previous_learners;
    uint256[] requested_learners;
}

//USER ACCOUNT 
struct employee {
    uint256 id;
    uint256 company_id;
    string name;
    string role;
    address wallet_address;
    bool is_employed;
    bool is_manager;
    bool is_approved;
    uint256 num_skill;
    uint256[] employee_skills;
    uint256[] employee_work_experience;
}

struct experience {
    string starting_date;
    string ending_date;
    string employee_name;
    string role;
    uint256 company_id;
    bool is_approved;
}

struct student {
    uint256 id;
    uint256 institute_id;
    uint256 edubukcompany_id;
    string name;
    address wallet_address;
    bool is_collegestudent;
    bool is_dean;
    bool is_edubukadmin;
    uint256 num_degree;
    uint256 num_skill;
    uint256 num_miitprofile;
    uint256 num_clp;
    uint256 num_grade;
    uint256 num_internship;
    uint256[] student_degrees;
    uint256[] student_skills;
    uint256[] student_miitprofiles;
    uint256[] student_clps;
    uint256[] student_grades;
    uint256[] student_internship_experience;
}

struct internship {
    string starting_date;
    string ending_date;
    string role;
    bool currently_intern;
    uint256 institute_id;
    bool is_approved;
}

struct learner {
    uint256 id;
    uint256 institute_id;
    uint256 expert_id;
    string name;
    address wallet_address;
    bool is_alearner;
    bool is_expert;
    uint256 num_skill;
    uint256[] learner_skills;
    uint256[] learner_project_experience;
}

struct project {
    string starting_date;
    string ending_date;
    string role;
    bool currently_enrolled;
    uint256 expert_id;
    bool is_approved;
}

struct edubukadmin {
    uint256 id;
    uint256 edubukcompany_id;
    string name;
    address wallet_address;
    bool is_edubukstudent;
    bool is_edubukadmin;
}

struct edubukcompany {
    uint256 id; 
    string name;
    address wallet_address;
    uint256[] current_students;
    uint256[] previous_students;
    uint256[] requested_students;
}

// Certificate , MIIT Profile , Skill , clp , Grade Verification 

struct certificate {
    string url;
    string issue_date;
    string valid_till;
    string name;
    uint256 id;
    string issuer;
}

struct skill {
    uint256 id;
    string name;
    bool verified;
    uint256[] skill_certifications;
    uint256[] skill_endorsements;
}

struct miitprofile {
    uint256 id;
    string name;
    bool verified;
    uint256[] miitprofile_certifications;
    uint256[] miitprofile_endorsements;
}

struct clp {
    uint256 id;
    string name;
    bool verified;
    uint256[] clp_certifications;
    uint256[] clp_endorsements;
}

struct grade {
    uint256 id;
    string name;
    bool verified;
    uint256[] grade_certifications;
    uint256[] grade_endorsements;
}

struct endorsment {
    uint256 endorser_id;
    string date;
    string comment;
}
                                 
//Dummy User Profile (To Remove the Employee from the Company's Employee List)
constructor() {
    employee storage dummy_employee = employees.push();
    dummy_employee.name = "dummy";
    dummy_employee.wallet_address = msg.sender;
    dummy_employee.id = 0;
    dummy_employee.employee_skills = new uint256[](0);
    dummy_employee.employee_work_experience = new uint256[](0);
}

//String Comparison Function
function memcmp(bytes memory a, bytes memory b)
    internal
    pure
    returns (bool)
{
    return (a.length == b.length) && (keccak256(a) == keccak256(b)); // Comapares the two hashes
}

function strcmp(string memory a, string memory b) // string comparison function
    internal
    pure
    returns (bool)
{
    return memcmp(bytes(a), bytes(b));
}

//Sign Up Process
function sign_up(
    address email,
    string calldata name,
    string calldata acc_type // account type (Company/employee/Institute/Student/expert/Learner)
) public {
    // first we check that account does not already exists
    // require(
    //     email_to_address[email] == address(0),
    //     "error: User already exists!"
    // );
    // email_to_address[email] = msg.sender;

    if (strcmp(acc_type, "employee")) { // for employee account type
        employee storage new_employee = employees.push(); // creates a new employee and returns the reference to it
        new_employee.name = name;
        new_employee.id = employees.length - 1; // give account a unique employee id
        new_employee.wallet_address = msg.sender;
        address_to_id[msg.sender] = new_employee.id;
        new_employee.employee_skills = new uint256[](0);
        new_employee.employee_work_experience = new uint256[](0);
        all_employees[email] = new_employee;    
    } else if (strcmp(acc_type, "company")) { // for company account type
        company storage new_company = companies.push(); // creates a new company and returns a reference to it
        new_company.name = name;
        new_company.id = companies.length - 1; // give account a unique company id
        new_company.wallet_address = msg.sender;
        new_company.current_employees = new uint256[](0);
        new_company.previous_employees = new uint256[](0);
        address_to_id[msg.sender] = new_company.id;
        is_company[msg.sender] = true;
    } else if (strcmp(acc_type, "student")) { // student account type
        student storage new_student = students.push(); // creates a new student and returns the reference to it
        new_student.name = name;
        new_student.id = students.length - 1; // give account a unique student id
        new_student.wallet_address = msg.sender;
        address_to_id[msg.sender] = new_student.id;
        new_student.student_skills = new uint256[](0);
        new_student.student_internship_experience = new uint256[](0);  
    } else if (strcmp(acc_type, "institute")) {
        institute storage new_institute = institutes.push(); // creates a new institute and returns a reference to it
        new_institute.name = name;
        new_institute.id = institutes.length - 1; // give account a unique institute id
        new_institute.wallet_address = msg.sender;
        new_institute.current_students = new uint256[](0);
        new_institute.previous_students = new uint256[](0);
        address_to_id[msg.sender] = new_institute.id;
        is_institute[msg.sender] = true;
    } else if (strcmp(acc_type, "learner")) { // learner account type
        learner storage new_learner = learners.push(); // creates a new learner and returns the reference to it
        new_learner.name = name;
        new_learner.id = learners.length - 1; // give account a unique learner id
        new_learner.wallet_address = msg.sender;
        address_to_id[msg.sender] = new_learner.id;
        new_learner.learner_skills = new uint256[](0);
        new_learner.learner_project_experience = new uint256[](0);  
    } else {
        expert storage new_expert = experts.push(); // creates a new expert and returns a reference to it
        new_expert.name = name;
        new_expert.id = experts.length - 1; // give account a unique expert id
        new_expert.wallet_address = msg.sender;
        new_expert.current_learners = new uint256[](0);
        new_expert.previous_learners = new uint256[](0);
        address_to_id[msg.sender] = new_expert.id;
        is_expert[msg.sender] = true;
    }
}

//Login Process
function logincompany(address email) public view returns (string memory) {
    // checking the function caller's wallet address from global map containing email address mapped to wallet address
    // require(
    // msg.sender == email_to_address[email],
    // "error: incorrect wallet address used for signing in"
    // );
    return (is_company[email]) ? "company" : "employee"; // returns account type
}

function logininstitute(address email) public view returns (string memory) {
    // checking the function caller's wallet address from global map containing email address mapped to wallet address
    // require(
    // msg.sender == email_to_address[email],
    // "error: incorrect wallet address used for signing in"
    // );
    return (is_institute[email]) ? "institute" : "student"; // returns account type
}

function loginexpert(address email) public view returns (string memory) {
    // checking the function caller's wallet address from global map containing email address mapped to wallet address
    // require(
    // msg.sender == email_to_address[email],
    // "error: incorrect wallet address used for signing in"
    // );
    return (is_expert[email]) ? "expert" : "learner";
}

//Updating a wallet Address
function update_wallet_address(address new_address)
    public
{
    // require(
    //     email_to_address[email] == msg.sender,
    //     "error: function called from incorrect wallet address"
    // );
    // email_to_address[email] = new_address;
    uint256 id = address_to_id[msg.sender];
    address_to_id[msg.sender] = 0;
    address_to_id[new_address] = id;
}
                                    

//Adding an Employee to a Company
function add_employee(
    uint256 employee_id,
    uint256 company_id
) public verifiedEmployee(employee_id) {
    employee storage new_employee = employees.push();
    new_employee.company_id = company_id;
    new_employee.is_approved = false;
    new_employee.name = employees[employee_id].name;
    companies[company_id].requested_employees.push(employees.length - 1);
}

//Adding an Experience to a Particular Employee
function add_experience(
    uint256 employee_id,
    string calldata starting_date,
    string calldata ending_date,
    string calldata role,
    uint256 company_id
) public verifiedEmployee(employee_id) {
    experience storage new_experience = experiences.push();
    new_experience.company_id = company_id;
    new_experience.is_approved = false;
    new_experience.starting_date = starting_date;
    new_experience.role = role;
    new_experience.ending_date = ending_date;
    new_experience.employee_name = employees[employee_id].name;
    employees[employee_id].employee_work_experience.push(experiences.length - 1);
    companies[company_id].requested_employees.push(experiences.length - 1);
}

//Adding an Internship to a Particular Student
function add_internship(
    uint256 student_id,
    string calldata starting_date,
    string calldata ending_date,
    string calldata role,
    uint256 institute_id
) public verifiedStudent(student_id) {
    internship storage new_internship = internships.push();
    new_internship.institute_id = institute_id;
    new_internship.currently_intern = false;
    new_internship.is_approved = false;
    new_internship.starting_date = starting_date;
    new_internship.role = role;
    new_internship.ending_date = ending_date;
    students[student_id].student_internship_experience.push(internships.length - 1);
    institutes[institute_id].requested_students.push(internships.length - 1);
}

//Adding Project to a Particular Learner
function add_project(
    uint256 learner_id,
    string calldata starting_date,
    string calldata ending_date,
    string calldata role,
    uint256 expert_id
) public verifiedLearner(learner_id) {
    project storage new_project = projects.push();
    new_project.expert_id = expert_id;
    new_project.currently_enrolled = false;
    new_project.is_approved = false;
    new_project.starting_date = starting_date;
    new_project.role = role;
    new_project.ending_date = ending_date;
    learners[learner_id].learner_project_experience.push(projects.length - 1);
    experts[expert_id].requested_learners.push(projects.length - 1);
}
       
//Process of Approval

//Approval of Experience
function approve_experience(uint256 exp_id, uint256 company_id) public {
      require(
          (is_company[msg.sender] &&
              companies[address_to_id[msg.sender]].id ==
              experiences[exp_id].company_id) ||
              (employees[address_to_id[msg.sender]].is_manager &&
                  employees[address_to_id[msg.sender]].company_id ==
                  experiences[exp_id].company_id),
          "error: approver should be the company account or a manager of the required company"
      );
    uint256 i;
    experiences[exp_id].is_approved = true;
    for (i = 0; i < companies[company_id].requested_employees.length; i++) {    
        if (companies[company_id].requested_employees[i] == exp_id) {
            companies[company_id].requested_employees[i] = 0;
            break;
        }
    }
    for (i = 0; i < companies[company_id].current_employees.length; i++) {
        if (companies[company_id].current_employees[i] == 0) {
            companies[company_id].requested_employees[i] = exp_id;
            break;
        }
    }
    if (i == companies[company_id].current_employees.length)
        companies[company_id].current_employees.push(exp_id);
}

function approve_employee(uint256 employee_id, uint256 company_id) public {
        require(
            (is_company[msg.sender] &&
                companies[address_to_id[msg.sender]].id ==
                employees[employee_id].company_id) ||
                (employees[address_to_id[msg.sender]].is_manager &&
                    employees[address_to_id[msg.sender]].company_id ==
                    employees[employee_id].company_id),
            "error: approver should be the company account or a manager of the required company"
        );
        uint256 i;
        employees[employee_id].is_approved = true;
        for (i = 0; i < companies[company_id].requested_employees.length; i++) {
            if (companies[company_id].requested_employees[i] == employee_id) {
                companies[company_id].requested_employees[i] = 0;
                break;
            }
        }
        for (i = 0; i < companies[company_id].current_employees.length; i++) {
            if (companies[company_id].current_employees[i] == 0) {
                companies[company_id].requested_employees[i] = employee_id;
                break;
            }
        }
        if (i == companies[company_id].current_employees.length)
            companies[company_id].current_employees.push(employee_id);
    }       

//Approval of Internship
function approve_internship(uint256 int_id, uint256 institute_id) public {
      require(
          (is_institute[msg.sender] &&
              institutes[address_to_id[msg.sender]].id ==
              internships[int_id].institute_id) ||
              (institutes[address_to_id[msg.sender]].is_dean &&
                  students[address_to_id[msg.sender]].institute_id ==
                  internships[int_id].institute_id),
          "error: approver should be the instructor account or an admin of the required institute"
      );
    uint256 i;
    internships[int_id].is_approved = true;
    for (i = 0; i < institutes[institute_id].requested_students.length; i++) {
        if (institutes[institute_id].requested_students[i] == int_id) {
            institutes[institute_id].requested_students[i] = 0;
            break;
        }
    }
    for (i = 0; i < institutes[institute_id].current_students.length; i++) {
        if (institutes[institute_id].current_students[i] == 0) {
            institutes[institute_id].requested_students[i] = int_id;
            break;
        }
    }
    if (i == institutes[institute_id].current_students.length)
        institutes[institute_id].current_students.push(int_id);
}

//Approval of Project
function approve_project(uint256 proj_id, uint256 expert_id) public {
      require(
          (is_expert[msg.sender] &&
              experts[address_to_id[msg.sender]].id ==
              projects[proj_id].expert_id) ||
              (experts[address_to_id[msg.sender]].is_expertadmin &&
                  learners[address_to_id[msg.sender]].expert_id ==
                  projects[proj_id].expert_id),
          "error: approver should be the expert account or an expert on the Edubuk Skilling Platform"
      );
    uint256 i;
    projects[proj_id].is_approved = true;
    for (i = 0; i < experts[expert_id].requested_learners.length; i++) {
        if (experts[expert_id].requested_learners[i] == proj_id) {
            experts[expert_id].requested_learners[i] = 0;
            break;
        }
    }
    for (i = 0; i < experts[expert_id].current_learners.length; i++) {
        if (experts[expert_id].current_learners[i] == 0) {
            experts[expert_id].requested_learners[i] = proj_id;
            break;
        }
    }
    if (i == experts[expert_id].current_learners.length)
        experts[expert_id].current_learners.push(proj_id);
}

//Approve a Manager
function approve_manager(uint256 employee_id) public {
        require(is_company[msg.sender], "error: sender not a company account");
    require(
        employees[employee_id].company_id == address_to_id[msg.sender],
        "error: employee not of the same company"
    );
    require(
        !(employees[employee_id].is_manager),
        "error: employee is already a manager"
    );
    employees[employee_id].is_manager = true;
}

//Approve a Dean
function approve_dean(uint256 dean_id) public {
        require(is_institute[msg.sender], "error: sender not a dean of the institute");
    require(
        students[dean_id].institute_id == address_to_id[msg.sender],
        "error: student not of the same institute"
    );
    require(
        !(students[dean_id].is_dean),
        "error: already enrolled as a dean"
    );
    students[dean_id].is_dean = true;
}

//Approve an Expert
function approve_expert(uint256 expert_id) public {
        require(is_expert[msg.sender], "error: sender not an expert on Edubuk's platform");
    require(
        learners[expert_id].expert_id == address_to_id[msg.sender],
        "error: learner not registered on Edubuk's platform"
    );
    require(
        !(learners[expert_id].is_expert),
        "error: not an expert"
    );
    learners[expert_id].is_expert = true;
}

//Skill Function (to push the input skill into the skills list)
function add_skill(uint256 employeeid, string memory skill_name)
    public
    verifiedEmployee(employeeid) { // the modifier that we created above
    skill storage new_skill = skills.push();
    employees[employeeid].employee_skills.push(skills.length - 1);
    new_skill.name = skill_name;
    new_skill.verified = false;
    new_skill.skill_certifications = new uint256[](0);
    new_skill.skill_endorsements = new uint256[](0);
}

//MIITProfile Function (to push the input MIITProfile into the MIITProfile list)
function add_miitprofile(uint256 studentid, string memory miitprofile_name)
    public
    verifiedStudent(studentid) { // the modifier that we created above
    miitprofile storage new_miitprofile = miitprofiles.push();
    students[studentid].student_miitprofiles.push(miitprofiles.length - 1);
    new_miitprofile.name = miitprofile_name;
    new_miitprofile.verified = false;
    new_miitprofile.miitprofile_certifications = new uint256[](0);
    new_miitprofile.miitprofile_endorsements = new uint256[](0);
}

//CLP Function (to push the input CLP into the CLP list) Customized Learning Plan
function add_clp(uint256 studentid, string memory clp_name)
    public
    verifiedStudent(studentid) { // the modifier that we created above
    clp storage new_clp = clps.push();
    students[studentid].student_clps.push(clps.length - 1);
    new_clp.name = clp_name;
    new_clp.verified = false;
    new_clp.clp_certifications = new uint256[](0);
    new_clp.clp_endorsements = new uint256[](0);
}

//Grade Function (to push the input Grade into the Grade list)
function add_grade(uint256 studentid, string memory grade_name)
    public
    verifiedStudent(studentid) { // the modifier that we created above
    grade storage new_grade = grades.push();
    students[studentid].student_grades.push(grades.length - 1);
    new_grade.name = grade_name;
    new_grade.verified = false;
    new_grade.grade_certifications = new uint256[](0);
    new_grade.grade_endorsements = new uint256[](0);
}

//certification Function (to push the input certification into the certification list)
function add_certification_skill(
    uint256 employee_id,
    string memory url,
    string calldata issue_date,
    string calldata valid_till,
    string calldata name,
    string calldata issuer,
    uint256 linked_skill_id
) public verifiedEmployee(employee_id) {
    certificate storage new_certificate = certifications.push();
    new_certificate.url = url;
    new_certificate.issue_date = issue_date;
    new_certificate.valid_till = valid_till;
    new_certificate.name = name;
    new_certificate.id = certifications.length - 1;
    new_certificate.issuer = issuer;
    skills[linked_skill_id].skill_certifications.push(new_certificate.id);
}

//certification MIIT Profile Function (to push the input certification MIIT Profile into the certification MIIT Profile list)
function add_certification_miitprofile(
    uint256 student_id,
    string memory url,
    string calldata issue_date,
    string calldata valid_till,
    string calldata name,
    string calldata issuer,
    uint256 linked_miitprofile_id
) public verifiedStudent(student_id) {
    certificate storage new_certificate = certifications.push();
    new_certificate.url = url;
    new_certificate.issue_date = issue_date;
    new_certificate.valid_till = valid_till;
    new_certificate.name = name;
    new_certificate.id = certifications.length - 1;
    new_certificate.issuer = issuer;
    miitprofiles[linked_miitprofile_id].miitprofile_certifications.push(new_certificate.id);
}

//certification CLP Function (to push the input certification CLP into the certification CLP list)
function add_certification_clp(
    uint256 student_id,
    string memory url,
    string calldata issue_date,
    string calldata valid_till,
    string calldata name,
    string calldata issuer,
    uint256 linked_clp_id
) public verifiedStudent(student_id) {
    certificate storage new_certificate = certifications.push();
    new_certificate.url = url;
    new_certificate.issue_date = issue_date;
    new_certificate.valid_till = valid_till;
    new_certificate.name = name;
    new_certificate.id = certifications.length - 1;
    new_certificate.issuer = issuer;
    clps[linked_clp_id].clp_certifications.push(new_certificate.id);
}

//certification CLP Function (to push the input certification Grade into the certification Grade list)
function add_certification_grade(
    uint256 student_id,
    string memory url,
    string calldata issue_date,
    string calldata valid_till,
    string calldata name,
    string calldata issuer,
    uint256 linked_grade_id
) public verifiedStudent(student_id) {
    certificate storage new_certificate = certifications.push();
    new_certificate.url = url;
    new_certificate.issue_date = issue_date;
    new_certificate.valid_till = valid_till;
    new_certificate.name = name;
    new_certificate.id = certifications.length - 1;
    new_certificate.issuer = issuer;
    grades[linked_grade_id].grade_certifications.push(new_certificate.id);
}

//Endrose Skill (Function can be called by a Manager, Coworker or any Employee)
//If the Endorsee is a Manager in the Employee's current Company this will also make the Employee's Skill Verified.
function endorse_skill(
    uint256 employee_id,
    uint256 skill_id,
    string calldata endorsing_date,
    string calldata comment
) public {
    endorsment storage new_endorsemnt = endorsments.push();
    new_endorsemnt.endorser_id = address_to_id[msg.sender];
    new_endorsemnt.comment = comment;
    new_endorsemnt.date = endorsing_date;
    skills[skill_id].skill_endorsements.push(endorsments.length - 1);
    if (employees[address_to_id[msg.sender]].is_manager) {
        if (
            employees[address_to_id[msg.sender]].company_id ==
            employees[employee_id].company_id
        ) {
            skills[skill_id].verified = true;
        }
    }
}

//Endrose MIIT Profile (Function can be called by a Edubuk Admin)
function endorse_miitprofile(
    uint256 student_id,
    uint256 miitprofile_id,
    string calldata endorsing_date,
    string calldata comment
) public {
    endorsment storage new_endorsemnt = endorsments.push();
    new_endorsemnt.endorser_id = address_to_id[msg.sender];
    new_endorsemnt.comment = comment;
    new_endorsemnt.date = endorsing_date;
    miitprofiles[miitprofile_id].miitprofile_endorsements.push(endorsments.length - 1);
    if (students[address_to_id[msg.sender]].is_edubukadmin) {
        if (
            students[address_to_id[msg.sender]].edubukcompany_id ==
            students[student_id].edubukcompany_id
        ) {
            miitprofiles[miitprofile_id].verified = true;
        }
    }
}

//Endrose CLP (Function can be called by a Edubuk Admin)
function endorse_clp(
    uint256 student_id,
    uint256 clp_id,
    string calldata endorsing_date,
    string calldata comment
) public {
    endorsment storage new_endorsemnt = endorsments.push();
    new_endorsemnt.endorser_id = address_to_id[msg.sender];
    new_endorsemnt.comment = comment;
    new_endorsemnt.date = endorsing_date;
    clps[clp_id].clp_endorsements.push(endorsments.length - 1);
    if (students[address_to_id[msg.sender]].is_edubukadmin) {
        if (
            students[address_to_id[msg.sender]].edubukcompany_id ==
            students[student_id].edubukcompany_id
        ) {
            clps[clp_id].verified = true;
        }
    }
}

//Endrose Grade (Function can be called by a Dean of an Institute)
function endorse_grade(
    uint256 student_id,
    uint256 grade_id,
    string calldata endorsing_date,
    string calldata comment
) public {
    endorsment storage new_endorsemnt = endorsments.push();
    new_endorsemnt.endorser_id = address_to_id[msg.sender];
    new_endorsemnt.comment = comment;
    new_endorsemnt.date = endorsing_date;
    grades[grade_id].grade_endorsements.push(endorsments.length - 1);
    if (students[address_to_id[msg.sender]].is_dean) {
        if (
            students[address_to_id[msg.sender]].institute_id ==
            students[student_id].institute_id
        ) {
            grades[grade_id].verified = true;
        }
    }
}

}