import { AfterViewInit, Component, ElementRef, HostListener, ViewChild } from '@angular/core';

@Component({
  selector: 'app-signature-pad',
  template: `
    <canvas
      #cv
      class="sigpad"
      (pointerdown)="onDown($event)"
      (pointermove)="onMove($event)"
      (pointerup)="onUp($event)"
      (pointercancel)="onUp($event)"
    ></canvas>
  `,
})
export class SignaturePad implements AfterViewInit {
  @ViewChild('cv', { static: true }) private canvasRef!: ElementRef<HTMLCanvasElement>;

  private drawing = false;
  private dirty = false;
  private ctx: CanvasRenderingContext2D | null = null;

  ngAfterViewInit(): void {
    this.fit();
  }

  @HostListener('window:resize')
  onResize(): void {
    const png = this.dirty ? this.canvas.toDataURL('image/png') : null;
    this.fit();
    if (!png || !this.ctx) return;
    const img = new Image();
    img.onload = () => {
      const c = this.canvas;
      this.ctx?.drawImage(img, 0, 0, c.clientWidth, c.clientHeight);
    };
    img.src = png;
  }

  snapshot(): string | null {
    return this.dirty ? this.canvas.toDataURL('image/png') : null;
  }

  hasInk(): boolean {
    return this.dirty;
  }

  clear(): void {
    this.dirty = false;
    this.fit();
  }

  private get canvas(): HTMLCanvasElement {
    return this.canvasRef.nativeElement;
  }

  private fit(): void {
    const canvas = this.canvas;
    const dpr = window.devicePixelRatio || 1;
    const w = Math.max(canvas.clientWidth, 1);
    const h = Math.max(canvas.clientHeight, 1);
    canvas.width = Math.round(w * dpr);
    canvas.height = Math.round(h * dpr);
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = '#1a1523';
    ctx.lineWidth = 2.2;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    this.ctx = ctx;
  }

  protected onDown(e: PointerEvent): void {
    if (!this.ctx) return;
    e.preventDefault();
    this.canvas.setPointerCapture(e.pointerId);
    this.drawing = true;
    const p = this.pos(e);
    this.ctx.beginPath();
    this.ctx.moveTo(p.x, p.y);
  }

  protected onMove(e: PointerEvent): void {
    if (!this.drawing || !this.ctx) return;
    e.preventDefault();
    const p = this.pos(e);
    this.ctx.lineTo(p.x, p.y);
    this.ctx.stroke();
    this.dirty = true;
  }

  protected onUp(e: PointerEvent): void {
    if (!this.drawing) return;
    this.drawing = false;
    try {
      this.canvas.releasePointerCapture(e.pointerId);
    } catch {
      /* already released */
    }
  }

  private pos(e: PointerEvent): { x: number; y: number } {
    const r = this.canvas.getBoundingClientRect();
    return { x: e.clientX - r.left, y: e.clientY - r.top };
  }
}
