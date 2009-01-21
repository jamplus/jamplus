// SimpleMFCView.h : interface of the CSimpleMFCView class
//


#pragma once


class CSimpleMFCView : public CView
{
protected: // create from serialization only
	CSimpleMFCView();
	DECLARE_DYNCREATE(CSimpleMFCView)

// Attributes
public:
	CSimpleMFCDoc* GetDocument() const;

// Operations
public:

// Overrides
public:
	virtual void OnDraw(CDC* pDC);  // overridden to draw this view
	virtual BOOL PreCreateWindow(CREATESTRUCT& cs);
protected:
	virtual BOOL OnPreparePrinting(CPrintInfo* pInfo);
	virtual void OnBeginPrinting(CDC* pDC, CPrintInfo* pInfo);
	virtual void OnEndPrinting(CDC* pDC, CPrintInfo* pInfo);

// Implementation
public:
	virtual ~CSimpleMFCView();
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

protected:

// Generated message map functions
protected:
	DECLARE_MESSAGE_MAP()
};

#ifndef _DEBUG  // debug version in SimpleMFCView.cpp
inline CSimpleMFCDoc* CSimpleMFCView::GetDocument() const
   { return reinterpret_cast<CSimpleMFCDoc*>(m_pDocument); }
#endif

