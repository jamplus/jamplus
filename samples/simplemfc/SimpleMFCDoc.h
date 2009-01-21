// SimpleMFCDoc.h : interface of the CSimpleMFCDoc class
//


#pragma once


class CSimpleMFCDoc : public CDocument
{
protected: // create from serialization only
	CSimpleMFCDoc();
	DECLARE_DYNCREATE(CSimpleMFCDoc)

// Attributes
public:

// Operations
public:

// Overrides
public:
	virtual BOOL OnNewDocument();
	virtual void Serialize(CArchive& ar);

// Implementation
public:
	virtual ~CSimpleMFCDoc();
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

protected:

// Generated message map functions
protected:
	DECLARE_MESSAGE_MAP()
};


