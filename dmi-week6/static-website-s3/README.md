# 🌩️ Week 6 – AWS S3 Static Website Deployment
## 📌 Overview

- As part of my DevOps Micro Internship (Week 6), I deployed a static portfolio website using Amazon S3 Static Website Hosting.

- This assignment helped me understand cloud storage, permissions, public access configuration, and deployment validation.

## 🛠️ Services Used

- Amazon Web Services

- Amazon S3

## 🎯 Learning Objectives Achieved

✔ Downloaded website template from GitHub
✔ Created globally unique S3 bucket
✔ Uploaded static website files correctly
✔ Enabled S3 static website hosting
✔ Configured bucket policy for public read access
✔ Verified website using S3 website endpoint
✔ Practiced update + redeployment workflow

## 📂 Assignment Breakdown

### ✅ Task 1 – Download Website Template

- Cloned the portfolio template repository and verified file structure locally.

- Key Learning: 
Understanding project structure before deployment prevents future errors.

### ✅ Task 2 – Create S3 Bucket

- Created a globally unique S3 bucket using naming best practices.

- Example naming format:
```
pravin-portfolio-venkatesh-ap-south-1
```

- Selected region: ap-south-1 (Mumbai)

- Key Learning: 
S3 bucket names are globally unique across AWS.

### ✅ Task 3 – Upload Website Files

Uploaded all static files ensuring:

- index.html is at root level

- CSS, JS, assets folders properly structured

- Key Learning: 
Most S3 website failures occur due to incorrect root structure.

### ✅ Task 4 – Enable Static Website Hosting

Configured:
```bash
Index document → index.html

Error document → error.html
```
- Obtained S3 website endpoint.

- Key Learning: 
S3 object URL ≠ Website endpoint.

### ✅ Task 5 – Configure Bucket Policy

Applied public read bucket policy:
```bash
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::<YOUR_BUCKET_NAME>/*"
    }
  ]
}

```
- Key Learning: 
Block Public Access settings override bucket policies if not configured properly.

### ✅ Task 6 – Website Verification

- Accessed the S3 website endpoint in browser and confirmed:

- Homepage loads

- CSS styling works

- Images render correctly

- No Access Denied errors

- Key Learning: 
Deployment is not complete until the public URL works successfully.

### ✅ Task 7 – Small Update + Redeploy

- Edited homepage tagline and re-uploaded index.html.

- Verified updated content after clearing browser cache.

- Key Learning: 
Even small changes require proper redeployment and validation.

## 🏗️ Production Insight

- For learning purposes, this assignment used:

- S3 Public Bucket + HTTP Endpoint

- In real production environments:

- S3 bucket is kept private

- CloudFront is placed in front

- HTTPS is enforced

- Origin Access Control (OAC) is used

### 💡 Key Takeaway

This assignment strengthened my understanding of:

- Cloud storage architecture
- Public access management
- Permission debugging
- Static hosting fundamentals

It was more than just uploading files — it was understanding how cloud systems serve content publicly.
