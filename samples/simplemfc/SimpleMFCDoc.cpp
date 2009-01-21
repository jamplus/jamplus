// SimpleMFCDoc.cpp : implementation of the CSimpleMFCDoc class
//

#include "stdafx.h"
#include "SimpleMFC.h"

#include "SimpleMFCDoc.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif


// CSimpleMFCDoc

IMPLEMENT_DYNCREATE(CSimpleMFCDoc, CDocument)

BEGIN_MESSAGE_MAP(CSimpleMFCDoc, CDocument)
END_MESSAGE_MAP()


// CSimpleMFCDoc construction/destruction

CSimpleMFCDoc::CSimpleMFCDoc()
{
	// TODO: add one-time construction code here

}

CSimpleMFCDoc::~CSimpleMFCDoc()
{
}

BOOL CSimpleMFCDoc::OnNewDocument()
{
	if (!CDocument::OnNewDocument())
		return FALSE;

	// TODO: add reinitialization code here
	// (SDI documents will reuse this document)

	return TRUE;
}




// CSimpleMFCDoc serialization

void CSimpleMFCDoc::Serialize(CArchive& ar)
{
	if (ar.IsStoring())
	{
		// TODO: add storing code here
	}
	else
	{
		// TODO: add loading code here
	}
}


// CSimpleMFCDoc diagnostics

#ifdef _DEBUG
void CSimpleMFCDoc::AssertValid() const
{
	CDocument::AssertValid();
}

void CSimpleMFCDoc::Dump(CDumpContext& dc) const
{
	CDocument::Dump(dc);
}
#endif //_DEBUG


// CSimpleMFCDoc commands
