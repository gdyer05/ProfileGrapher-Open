# **ProfileGrapher**
#### GUI Interface for Microsoft Graph SDK
ProfileGrapher is a Powershell-Based WinForms UI which interacts with Microsoft's Graph SDK. It is designed to display Summarized, Interactive Information for a User's Profile. ProfileGrapher allows for users of Varying Entra Access Permissions to export summarized Excel Spreadsheets for analysis.

## Getting Started
Running '.\\ProfileGrapher.ps1' will display a Launcher which prompts the User to Log In with Microsoft. The User must know what permissions they have access to, and must have their Privileged Roles enabled through Entra.

After Selecting the Applicable Permissions and Signing In with Microsoft, ProfileGrapher will automatically reload all of the Microsoft Graph API and install the required Packages and DLLs from the Online Repository. This process takes approximately 15 seconds.

## Navigating the Interface (Left)
Starting with the Top Left Corner of the Main Window, is the Search Bar. This input accepts an Email related to the domain in which ProfileGrapher is configured for. Typing the first half of an email, excluding the @domain.ext will automatically fill it in using the pre-configured fallback.

Upon Searching for a Valid User, the Identity Preview located just below the Search bar will display the Profile Image, Name, Position, and Email of the User. Just below are the Basic Account Details, which includes basic information about the Account's Status, IDs and Activity Dates. Finally, below this is a list of all Licenses and Plans assigned to a User. Licenses will display their name, as well as provide a list of Plans which are disabled by the License. Plans will display whether they are active, and which Licenses influence them.

## Navigating the Tabs (Right)
To the Right side of the Main Window is a Wide Selection of Tabs. These Tabs are displayed or hidden based on the Selected Permissions given to the Launcher. Located in each Tab is an interactive display of information about different aspects of the Account, including the majority of information a User may need to know about an Account, cleanly summarized and formatted.

Here is a Quick Overview of Each Tab:
* **Authentication and Sign-Ins:**
  Shows the Most Recent Sign-In History and Multi-Factor Authentication features Enabled under this account
* **Roles and Groups:**
  Displays a List of all Privileged Roles and Directory Groups assigned to the User at the given time. Includes the Group's Creation Date and a Description of the Group, if provided.
* **Device Compliance:**
  Displays a list of Devices in the Domain Associated with the User, as well as details regarding a Computer's Model, Management Status, and Approximate Last Sign-In Date.
* **Audit Logs:**
  Displays a list of Audit Log Entries related to a user's account, including Audits targeting the account, and Audits initiated by the account. Limited to 30-Day History Length.
* **Risk Assessment:**
  Displays a Brief Summary of the Account's Current Risk Status, as well as a Flagged Activity list. This Activity log prioritizes the most recent action regarding a prior event's updates.

## Exporting Information
In the Top Right Corner of the Main Window, next to the Query Progress bar, are two buttons. The 'Export' Button will allow the User to Export a Spreadsheet of information regarding the Last-Searched User's Account. The 'Batch Export' Button allows the User to upload a text file containing User Emails, with options to export the Data as combined or separate spreadsheets.

Upon selecting an Export Button (and selecting the User or Users to export), a Small Dialogue Window will appear. Make sure that the 'Exporting Data For:' text is accurately displaying what you want to Export before continuing.

On the Left, Select or Unselect the features which will be included in the Spreadsheet. On the Right, there are Three Buttons, one of which will be greyed out, depending on whether you are exporting one or multiple users.
* **Export All (.xslx)**
  This button will Export all information as a singular multi-sheet Excel File. Do Note, this option will truncate most of the information from a normal export in Batch Mode. This option **REQUIRES** Excel be installed on the Computer to function.
  
* **Export Separate Users (.xslx)**
  This button will Export multiple multi-sheet Excel Files, One File Per User. This option is preferrable for Smaller Batch Sizes, and is required to get a full export for a Batch of Users. This option **REQUIRES** Excel be installed on the Computer to function.
  
* **Individual Export (.csv)**
  This button will Export multiple CSV files for a Single User. This is a Compatibility option and is not File-Count-Efficient, so it is locked to Single User only. It is recommended to use Export All over Individual Export.