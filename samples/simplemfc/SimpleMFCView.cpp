// SimpleMFCView.cpp : implementation of the CSimpleMFCView class
//

#include "stdafx.h"
#include "SimpleMFC.h"

#include "SimpleMFCDoc.h"
#include "SimpleMFCView.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif


// CSimpleMFCView

IMPLEMENT_DYNCREATE(CSimpleMFCView, CView)

BEGIN_MESSAGE_MAP(CSimpleMFCView, CView)
	// Standard printing commands
	ON_COMMAND(ID_FILE_PRINT, &CView::OnFilePrint)
	ON_COMMAND(ID_FILE_PRINT_DIRECT, &CView::OnFilePrint)
	ON_COMMAND(ID_FILE_PRINT_PREVIEW, &CView::OnFilePrintPreview)
END_MESSAGE_MAP()

// CSimpleMFCView construction/destruction

CSimpleMFCView::CSimpleMFCView()
{
	// TODO: add construction code here

}

CSimpleMFCView::~CSimpleMFCView()
{
}

BOOL CSimpleMFCView::PreCreateWindow(CREATESTRUCT& cs)
{
	// TODO: Modify the Window class or styles here by modifying
	//  the CREATESTRUCT cs

	return CView::PreCreateWindow(cs);
}

// CSimpleMFCView drawing

void CSimpleMFCView::OnDraw(CDC* /*pDC*/)
{
	CSimpleMFCDoc* pDoc = GetDocument();
	ASSERT_VALID(pDoc);
	if (!pDoc)
		return;

	// TODO: add draw code for native data here
}


// CSimpleMFCView printing

BOOL CSimpleMFCView::OnPreparePrinting(CPrintInfo* pInfo)
{
	// default preparation
	return DoPreparePrinting(pInfo);
}

void CSimpleMFCView::OnBeginPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/)
{
	// TODO: add extra initialization before printing
}

void CSimpleMFCView::OnEndPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/)
{
	// TODO: add cleanup after printing
}


// CSimpleMFCView diagnostics

#ifdef _DEBUG
void CSimpleMFCView::AssertValid() const
{
	CView::AssertValid();
}

void CSimpleMFCView::Dump(CDumpContext& dc) const
{
	CView::Dump(dc);
}

CSimpleMFCDoc* CSimpleMFCView::GetDocument() const // non-debug version is inline
{
	ASSERT(m_pDocument->IsKindOf(RUNTIME_CLASS(CSimpleMFCDoc)));
	return (CSimpleMFCDoc*)m_pDocument;
}
#endif //_DEBUG


// CSimpleMFCView message handlers
