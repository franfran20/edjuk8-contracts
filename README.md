# Edjuk-8 Overview

Edjuk-8 (pronounced as educate) is an educational platform aimed at enhancing the quality of learning content by offering educators and instructors adequate financing through the assetization of courses. This model allows individuals to invest in courses, earning passive interest while supporting the education sector. By financially empowering educators, Edjuk8 ensures the ongoing production of high-quality educational materials for students worldwide.


<!-- edjuk8 image overview here -->
![Edjuk8 Overview](https://salmon-thick-gazelle-208.mypinata.cloud/ipfs/Qmf8U9yhFw2eoibfAXE2RGf6b7omRDzxuR8v3tuZzjmwF7/edjuk8-overview.png)


## Core Concepts On Edjuk-8

Here are some of the core conecpts that drive the vision of edjuk-8

### Edjuk-8 Token

The Edjuk8 token is an ERC-20 token used to facilitate payments within the Edjuk8 platform.


### Courses

Courses on Edjuk8 are considered assets linked to a specific educator or instructor. Each course typically contains several subcourses focused on a particular field of study or topic, which we will explore shortly. An educator or instructor can create multiple courses, with a current limit of 8 upon deployment.

For example, a well-structured course could be a Cooking Course that includes subcourses on various national cuisines, such as Japanese, Italian, Colombian, or Nigerian dishes. Similarly, a Drawing Course might consist of subcourses on topics like drawing animals, creating animated characters, or landscape drawing.

Courses provide a comprehensive overview of a particular area of interest and are composed of subcourses that educators can release individually or in batches. When designing courses, educators should consider the various fields their course encompasses and plan their content releases 
accordingly.


<!-- Course Diagram -->
![edjuk8 course diagram](https://salmon-thick-gazelle-208.mypinata.cloud/ipfs/Qmf8U9yhFw2eoibfAXE2RGf6b7omRDzxuR8v3tuZzjmwF7/edjuk8-course-overview.png)



### Course Shares
Courses on Edjuk8 have what we call course shares, which are fixed at 100 (with 4 decimal places in the smart contract). This 100 represents 100% of the course shares, which are initially given entirely to the creator upon course creation. These shares effectively assetize courses, allowing an educator's course shares to enter the market to be sold, resold, and purchased.

Course shares enable individuals who wish to support the educational sector to invest in educators by buying shares they list for sale. This includes supporters who aim to improve the quality of educational content and those looking for a potential profit while contributing to the sector. Educators are not required to sell their shares; they can retain 100% ownership. However, to raise funds for activities that enhance their content, they may choose to list a portion of their shares for sale at a set price and attract investors by demonstrating the value of their course.

Think of this as angel investing in educational content, supporting educators in creating better content and improving their audience's knowledge.

##### How Course Shares Work:

- Upon course creation, 100% of the shares are allocated to the educator.
- The educator can choose to sell some of these shares in the marketplace but must retain at least 30% ownership (30 shares). Selling shares can help them raise funds to enhance the quality of their content. For example, an artist may need to raise money to buy expensive paints for future lessons by listing some shares for sale.
- Once shares enter the market, they can be traded freely. The educator has no control over subsequent sales once the initial shares are sold.


Anyone who is not the course educator (owner) but holds course shares is considered a shareholder. When a student enrolls in a subcourse, the funds are allocated to the main course and distributed among all shareholders and the educator, updating their respective balances. Shareholders can cash in their shares to receive their current value, returning the course share to the educator. This value might be significantly higher than the initial purchase price.

However, potential investors should exercise caution and conduct due diligence before purchasing shares. While there is an opportunity to profit, if the course's subcourses do not attract enough enrollments, they may receive less than their initial investment.

In essence, course shares enable the assetization of courses, helping educators raise funds to improve educational content while allowing financial supporters to potentially earn passively from the success of these courses.


### Subcourses

A subcourse provides a way to incentivize course shareholders to hold their shares longer and continue supporting the educator in creating quality educational content. Subcourses can be created at any time by the course owner and serve as the primary courses that learners interact with, as they contain the lesson content available upon enrollment.

Each subcourse is a smart contract deployed to its own unique address, containing all its details and lesson content links. To access the lessons, users enroll in a subcourse by paying an enrollment fee, which is then transferred to the main course. This updates the share balances of the owner and shareholders.

Subcourses are created to cover specific subtopics within a larger field of study that are significant enough to stand alone. For example, a course on data science could have subcourses on topics like natural language processing, data engineering and pipelining, and machine learning. At the time of deployment, each course is limited to a maximum of 8 subcourses.

![edjuk8 course share diagram](https://salmon-thick-gazelle-208.mypinata.cloud/ipfs/Qmf8U9yhFw2eoibfAXE2RGf6b7omRDzxuR8v3tuZzjmwF7/subcourse-lesson-share-flow.png)

### Lessons

Subcourses contain lessons that are specific to each subcourse. Lessons can be of two types: videos and articles, with articles written in Markdown format. The content of these lessons is stored outside the blockchain (using IPFS, databases, CDNs, etc.), and access is controlled based on conditions set in the subcourse contract. For example, if a user has enrolled in a subcourse, the content is released; otherwise, access is restricted.

While the ideal choice for this would have been the LIT protocol, it is not supported on Open Campus. Instead, I have used a combination of MongoDB, IPFS, and a custom API to handle lesson storage. This solution is not perfect, but it is sufficient to present the MVP, which focuses on the assetization of courses to enhance the quality of educational content for learners while providing a funding source for educators and investors—a win-win scenario.

In essence, when users enroll in a subcourse and pay the enrollment fee, they gain access to the associated lessons. The fees collected are directed to the main course and distributed among shareholders and the course educator.


### Share MarketPlace

When courses are created, the shares are not immediately available on the market for users to buy and support the educator. Course owners retain 100% of the shares upon creation and are not obligated to sell them at any time. Shareholders are not required unless the educator needs funding for specific operations. It is entirely up to the course owner to decide when, how much, and whether to sell their course shares.

When an educator chooses to list course shares for sale—whether it’s 0.5% or 30%—they do so on the course share marketplace, specifying the amount they wish to sell and the desired price. Interested users can then purchase these shares to support the educator and use them in various ways, such as reselling them for a higher price, holding them until their value increases, or using the underlying value as collateral for other purposes.

Currently, the share marketplace allows only one share listing per course at a time.

# Subcourse Issuance Code System

This feature, limited on the frontend due to time constraints, is designed for the final lesson to issue a 200 status code to the subcourse for users who have completed the course. The purpose of this code is to provide a credential or status defined by the educator, which can be implemented in any other contract. Essentially, it serves as a form of recognition or certification that can only be issued by the subcourse creator.

For example, by default, a user who has enrolled in a subcourse can issue themselves a 200 status code upon completing the final lesson. This code indicates that the user has not only enrolled in the course but has also successfully completed it.

Educators can further enhance this by conducting exams on an external platform, perhaps every quarter. If a user passes the exam, the educator could issue a 512 status code (or any other number, based on their preference), indicating that the user has both enrolled in and passed an additional qualification, demonstrating their understanding of the course content. This opens up possibilities for other smart contracts on-chain to use these status codes from high-quality courses as credentials.

### Links

1. Youtube Video - https://www.youtube.com/watch?v=Ld1VdIMviu8
2. Frontend Demo -https://edjuk8.vercel.app/
3. Smart contracts repo - https://github.com/franfran20/savesphere_contracts